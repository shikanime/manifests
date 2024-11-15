#!/bin/bash

for dir in apps/*/base infra/*; do
  if [ -f "$dir/update.sh" ]; then
    bash "$dir/update.sh" 2>&1 |
    if [[ $dir == infra/* ]]; then
      name=$(basename "$dir")
    fi
    echo "[$name] Running update script in $dir"
      sed "s/^/[$(basename "$dir")] /" &
  fi
done

wait
