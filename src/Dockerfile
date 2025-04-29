FROM node:18-slim

RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    zip \
    unzip \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/aws-cli && \
    /opt/aws-cli/bin/pip install --no-cache-dir awscli && \
    ln -s /opt/aws-cli/bin/aws /usr/local/bin/aws

RUN npm install -g serverless@latest

WORKDIR /app

COPY deploy.sh /app/deploy.sh
COPY serverless.yaml /app/serverless.yaml
COPY handler.js /app/handler.js

RUN chmod +x /app/deploy.sh

ENTRYPOINT ["/app/deploy.sh"]
LABEL org.opencontainers.image.source="https://github.com/NolanJMcCafferty/serverless-framework"