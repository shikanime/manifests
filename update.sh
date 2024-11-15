#!/bin/bash

for dir in apps/*/base infra/*; do
  if [ -f "$dir/update.sh" ]; then
    name=$(basename $(dirname "$dir"))
    if [[ $dir == infra/* ]]; then
      name=$(basename "$dir")
    fi
    echo "[$name] Running update script in $dir"
      sed "s/^/[$(basename "$dir")] /" &
  fi
done

wait
