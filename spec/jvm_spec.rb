require_relative 'spec_helper'

describe "JVM Metrics" do

  before(:each) do
    init_app(app)
  end

  context "on JDK 8" do
    let(:jdk_version) { "1.8" }

    context "a Gradle app" do
      let(:app) do
        Hatchet::Runner.new(
          "gradle-getting-started",
          buildpacks: [Hatchet::App.default_buildpack, "heroku/gradle"]
        )
      end

      it "deploys successfully" do
        app.deploy do |app|
          expect(app.output).to include("HerokuRuntimeMetrics app detected")
          expect(app.output).to include("Building Gradle app")
          expect(app.output).to include("executing ./gradlew stage")
          expect(app.output).to include("BUILD SUCCESSFUL")
          expect(successful_body(app)).to include("Getting Started with Gradle on Heroku")
        end
      end
    end

    context "a Scala app" do
      let(:app) do
        Hatchet::Runner.new(
          "scala-getting-started",
          buildpacks: [Hatchet::App.default_buildpack, "heroku/scala"]
        )
      end

      it "deploys successfully" do
        app.deploy do |app|
          expect(app.output).to include("HerokuRuntimeMetrics app detected")
          expect(app.output).to include("Installing OpenJDK #{jdk_version}")
          expect(app.output).to match("Running: sbt compile stage")
          expect(successful_body(app)).to include("Getting Started with Scala on Heroku")
        end
      end
    end

    context "a Java app" do
      let(:app) do
        Hatchet::Runner.new(
          "java-getting-started",
          buildpacks: [Hatchet::App.default_buildpack, "heroku/java"]
        )
      end

      it "deploys successfully" do
        app.deploy do |app|
          expect(app.output).to include("HerokuRuntimeMetrics app detected")
          expect(app.output).to include("Installing OpenJDK #{jdk_version}")
          expect(app.output).to include("BUILD SUCCESS")
          expect(app.output).not_to include("BUILD FAILURE")
          expect(successful_body(app)).to include("Getting Started with Java on Heroku")
        end
      end
    end
  end
end
