#!/usr/bin/env bash
set -euo pipefail

paths=("$@")
if [ ${#paths[@]} -eq 0 ]; then
  paths=(src examples docs build.zig)
fi

exec zig fmt --color auto "${paths[@]}"
