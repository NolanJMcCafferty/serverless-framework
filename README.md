# Serverless Framework with Omnistrate

This repository contains a sample Serverless Framework SaaS using Omnistrate.

## Prerequisites
Omnistrate CLI installed and configured. See [Omnistrate CLI Installation](https://docs.omnistrate.com/getting-started/compose/getting-started-with-ctl/?h=ctl#getting-started-with-omnistrate-ctl) for instructions.

## Setup

Create the Serverless Framework service template using the `spec-serverless.yaml` file. This file contains the configuration for the Serverless Framework deployment.

```
omctl build-from-repo -f spec-serverless.yaml --service-name Serverless Framework
```

This command packages the Serverless Framework deployer image and uploads it to your GitHub Container Registry as part of the service build process.
