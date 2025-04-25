#!/bin/bash
set -e

echo "Starting serverless deployment process..."

if [ -z "$1" ]; then
  echo "Error: No serverless YAML file specified."
  echo "Usage: docker run [options] my-serverless-container /path/to/serverless.yml"
  exit 1
fi

SERVERLESS_FILE="$1"
if [ ! -f "$SERVERLESS_FILE" ]; then
  echo "Error: Serverless file '$SERVERLESS_FILE' not found."
  exit 1
fi

echo "Using serverless file: $SERVERLESS_FILE"

SERVERLESS_DIR=$(dirname "$SERVERLESS_FILE")
cd "$SERVERLESS_DIR"

if [ -f "package.json" ]; then
  echo "Found package.json, installing dependencies..."
  npm install
fi

echo "Executing: serverless deploy --config $(basename "$SERVERLESS_FILE")"
serverless deploy --config $(basename "$SERVERLESS_FILE")

echo "Deployment completed successfully!"
