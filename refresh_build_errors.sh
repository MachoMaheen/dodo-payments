#!/bin/bash

# Run docker compose build and filter for errors and warnings
# Overwriting the previous log file
docker compose up --build 2>&1 | grep -i "error\|warning" > build_errors.log

echo "Build errors and warnings have been saved to build_errors.log"
