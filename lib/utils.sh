#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

# Extracts the barnes gem version from a Gemfile.lock
#
# ```
# barnes_version "Gemfile.lock"
# # => "0.1.0"
# ```
barnes_version() {
  local gemfile_lock="$1"
  grep -E '^[[:space:]]+barnes[[:space:]]+\(' "$gemfile_lock" | sed -E 's/.*barnes \(([^)]+)\).*/\1/'
}

# Determines which string is greater or equal
#
# ```
# version_gte "1.0.0" "1.0.0"; echo $? # => 0
# version_gte "1.0.1" "1.0.0"; echo $? # => 0
# version_gte "1.0.0" "1.0.1"; echo $? # => 1
# ```
version_gte() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}
