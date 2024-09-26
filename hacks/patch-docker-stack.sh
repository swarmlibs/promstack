#!/bin/bash
# Remove first line from docker-stack.yml file, which is the "version:" line
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' '1d' "${1:-docker-stack.yml}"
else
  sed -i '1d' "${1:-docker-stack.yml}"
fi
