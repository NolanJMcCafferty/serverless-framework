#!/bin/bash
set -e

echo "Starting serverless deployment process..."

# Always use the serverless.yaml file in the current directory
SERVERLESS_FILE="/app/serverless.yaml"

if [ ! -f "$SERVERLESS_FILE" ]; then
  echo "Error: Serverless file '$SERVERLESS_FILE' not found."
  exit 1
fi

echo "Using serverless file: $SERVERLESS_FILE"

# We're already in /app directory, so no need to change directories
# But keeping logic in case file structure changes in the future
SERVERLESS_DIR=$(dirname "$SERVERLESS_FILE")
cd "$SERVERLESS_DIR"

if [ -f "package.json" ]; then
  echo "Found package.json, installing dependencies..."
  npm install
fi

echo "Executing: serverless deploy --config $(basename "$SERVERLESS_FILE")"
serverless deploy --config $(basename "$SERVERLESS_FILE")

echo "Deployment completed successfully!"