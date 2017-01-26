// Copyright 2014 Prometheus Team
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"mime"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/matttproud/golang_protobuf_extensions/pbutil"
	"github.com/prometheus/common/expfmt"
	"github.com/prometheus/log"

	dto "github.com/prometheus/client_model/go"
)

const acceptHeader = `application/vnd.google.protobuf;proto=io.prometheus.client.MetricFamily;encoding=delimited;q=0.7,text/plain;version=0.0.4;q=0.3`

type metricFamily struct {
	Name    string        `json:"name"`
	Help    string        `json:"help"`
	Type    string        `json:"type"`
	Metrics []interface{} `json:"metrics,omitempty"` // Either metric or summary.
}

type payload struct {
	Counters  map[string]float64        `json:"counters"`
	Gauges    map[string]float64        `json:"gauges"`
	Summaries map[string]summaryPayload `json:"summaries"`
}

type summaryPayload struct {
	Sum       float64            `json:"sum"`
	Count     float64            `json:"count"`
	Quantiles map[string]float64 `json:"quantiles"`
}

func maybeApplyMetric(dtoMF *dto.MetricFamily, p *payload) {
	name := dtoMF.GetName()

	switch dtoMF.GetType() {
	case dto.MetricType_GAUGE:
		for _, m := range dtoMF.Metric {
			p.Gauges[name+suffixFor(m)] = getValue(m)
		}

	case dto.MetricType_COUNTER:
		for _, m := range dtoMF.Metric {
			p.Counters[name+suffixFor(m)] = getValue(m)
		}

	case dto.MetricType_SUMMARY:
		for _, m := range dtoMF.Metric {
			sp := summaryPayload{
				Count: float64(m.GetSummary().GetSampleCount()),
				Sum:   float64(m.GetSummary().GetSampleSum()),
			}

			for _, q := range m.GetSummary().Quantile {
				sp.Quantiles["p"+strconv.Itoa(int(100*q.GetQuantile()))] = q.GetValue()
			}

			p.Summaries[name+suffixFor(m)] = sp
		}

	case dto.MetricType_HISTOGRAM:
		log.Printf("Skipping HISTOGRAM: name=%s", name, dtoMF)
	case dto.MetricType_UNTYPED:
		log.Println("Skipping UNTYPED: name=%s", name, dtoMF)
	}
}

func getValue(m *dto.Metric) float64 {
	if m.Gauge != nil {
		return m.GetGauge().GetValue()
	}
	if m.Counter != nil {
		return m.GetCounter().GetValue()
	}
	if m.Untyped != nil {
		return m.GetUntyped().GetValue()
	}
	return 0
}

func suffixFor(m *dto.Metric) string {
	result := make([]string, 0, len(m.Label))

	for _, lp := range m.Label {
		result = append(result, lp.GetName()+"_"+lp.GetValue())
	}

	if len(result) == 0 {
		return ""
	}
	return "_" + strings.Join(result, "_")
}

func fetchMetricFamilies(url string, ch chan<- *dto.MetricFamily) {
	defer close(ch)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		log.Fatalf("creating GET request for URL %q failed: %s", url, err)
	}
	req.Header.Add("Accept", acceptHeader)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatalf("executing GET request for URL %q failed: %s", url, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		log.Fatalf("GET request for URL %q returned HTTP status %s", url, resp.Status)
	}

	mediatype, params, err := mime.ParseMediaType(resp.Header.Get("Content-Type"))
	if err == nil && mediatype == "application/vnd.google.protobuf" &&
		params["encoding"] == "delimited" &&
		params["proto"] == "io.prometheus.client.MetricFamily" {
		for {
			mf := &dto.MetricFamily{}
			if _, err = pbutil.ReadDelimited(resp.Body, mf); err != nil {
				if err == io.EOF {
					break
				}
				log.Fatalln("reading metric family protocol buffer failed:", err)
			}
			ch <- mf
		}
	} else {
		// We could do further content-type checks here, but the
		// fallback for now will anyway be the text format
		// version 0.0.4, so just go for it and see if it works.
		var parser expfmt.TextParser
		metricFamilies, err := parser.TextToMetricFamilies(resp.Body)
		if err != nil {
			log.Fatalln("reading text format failed:", err)
		}
		for _, mf := range metricFamilies {
			ch <- mf
		}
	}
}

var (
	scrapeURL = flag.String("scrape-url", "", "Scrape URL")
	sinkURL   = flag.String("url", "", "Destination URL")
	interval  = flag.Int("interval", 5, "Default interval for waiting between posts")
)

func main() {
	// Limit processing power to max 2 CPUs.
	runtime.GOMAXPROCS(2)

	flag.Parse()

	if *sinkURL == "" || *scrapeURL == "" {
		flag.Usage()
		os.Exit(2)
	}

	interval := time.Second * time.Duration(*interval)
	timer := time.NewTimer(interval)

	for {
		select {
		case <-timer.C:
			mfChan := make(chan *dto.MetricFamily, 1024)
			go fetchMetricFamilies(*scrapeURL, mfChan)

			p := payload{}

			for mf := range mfChan {
				maybeApplyMetric(mf, &p)
			}

			if err := post(p); err != nil {
				log.Printf("metrics-poller: error=%s", err)
			}
		}
		timer.Reset(interval)
	}
}

func post(p payload) error {
	buf := bytes.Buffer{}
	enc := json.NewEncoder(&buf)
	err := enc.Encode(p)
	if err != nil {
		return err
	}

	resp, err := http.Post(*sinkURL, "application/json", &buf)
	if err != nil {
		return err
	}
	resp.Body.Close()
	if resp.StatusCode > 299 {
		err = fmt.Errorf("Expected 2XX code, got %d", resp.StatusCode)
	}
	return err
}
