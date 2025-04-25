#!/bin/bash
set -e

# Output message to indicate the script is running
echo "Starting serverless deployment process..."

# Check for authentication variables
if [ -z "$SERVERLESS_ACCESS_KEY" ] && [ -z "$SERVERLESS_LICENSE_KEY" ]; then
  echo "Warning: Neither SERVERLESS_ACCESS_KEY nor SERVERLESS_LICENSE_KEY environment variables are set."
  echo "Serverless Framework v4+ requires authentication."
  echo "Please provide one of these environment variables when running the container."
fi

# Check if S3_SERVERLESS_CONFIG is provided
if [ -n "$S3_SERVERLESS_CONFIG" ]; then
  echo "Downloading serverless.yml from S3: $S3_SERVERLESS_CONFIG"
  # Extract bucket and key from S3 URI (s3://bucket-name/path/to/serverless.yml)
  S3_BUCKET=$(echo $S3_SERVERLESS_CONFIG | cut -d'/' -f3)
  S3_KEY=$(echo $S3_SERVERLESS_CONFIG | cut -d'/' -f4-)
  
  # Download the file
  aws s3 cp $S3_SERVERLESS_CONFIG /app/serverless.yml
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download serverless config file from S3."
    exit 1
  fi
  
  SERVERLESS_FILE="/app/serverless.yml"
else
  # Use the file path provided as command-line argument
  # Check if a file path was provided
  if [ -z "$1" ]; then
    echo "Error: No serverless YAML file specified and S3_SERVERLESS_CONFIG not set."
    echo "Usage: docker run -e S3_SERVERLESS_CONFIG=s3://bucket/path/to/serverless.yml [options] my-serverless-container"
    echo "   or: docker run [options] my-serverless-container /path/to/serverless.yml"
    exit 1
  fi

  SERVERLESS_FILE="$1"
fi

# Validate that the file exists
if [ ! -f "$SERVERLESS_FILE" ]; then
  echo "Error: Serverless file '$SERVERLESS_FILE' not found."
  exit 1
fi

echo "Using serverless file: $SERVERLESS_FILE"

# Change to the directory containing the serverless file
SERVERLESS_DIR=$(dirname "$SERVERLESS_FILE")
cd "$SERVERLESS_DIR"

# Run npm install if package.json exists in the directory
if [ -f "package.json" ]; then
  echo "Found package.json, installing dependencies..."
  npm install
fi

# Execute serverless deploy with the specified file
echo "Executing: serverless deploy --config $(basename "$SERVERLESS_FILE")"
serverless deploy --config $(basename "$SERVERLESS_FILE")

echo "Deployment completed successfully!"