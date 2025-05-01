# Serverless Framework with Omnistrate

This repository contains a sample Serverless Framework SaaS using Omnistrate.

## Prerequisites
Omnistrate CLI installed and configured. See [Omnistrate CLI Installation](https://docs.omnistrate.com/getting-started/compose/getting-started-with-ctl/?h=ctl#getting-started-with-omnistrate-ctl) for instructions.

## Setup

Create the Serverless Deployer service template using the `spec-serverless-job.yaml` file. This file contains the configuration for the Serverless Deployer job that will create the specified Lambda and API Gateway resources.

```
omctl build-from-repo -f spec-serverless-job.yaml --service-name 'Serverless Deployer
```

This command packages the Serverless Framework deployer image and uploads it to your GitHub Container Registry as part of the service build process.

Next, create the IdeaBox service using the `spec-terraform.yaml` file. This service contains the rest of the AWS resources for your service, defined in Terraform. In this example, we include a RDS instance, VPC resources, and SSM parameter stores.

```
omctl build -f spec-terraform.yaml --name 'IdeaBox' --release-as-preferred --spec-type ServicePlanSpec
```

To deploy an IdeaBox instance end-to-end, use the Omnistrate service orchestration framework. 

```
omnistrate-ctl services-orchestration create --dsl-file orchestration/create.yaml
```

This command will first deploy a Serverless Deployer job, and then pass an output of that job to the IdeaBox terraform service to complete the deployment. You can then call your Serverless function at the address specified by the `api_gateway_endpoint` output parameter.
