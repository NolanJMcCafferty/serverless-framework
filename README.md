# Serverless Framework Deployment Container

This Docker container provides a simple way to deploy AWS Lambda functions using the Serverless Framework. The container includes the Serverless Framework CLI and all necessary dependencies.

## Build the Container

```bash
docker build -t serverless-deployer .
```

## Usage

The container takes a single parameter: the path to your serverless.yml file.

```bash
docker run -v $(pwd):/app/project \
  -e AWS_ACCESS_KEY_ID=your_access_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret_key \
  -e AWS_REGION=your_region \
  -e SERVERLESS_ACCESS_KEY=your_serverless_access_key \
  serverless-deployer /app/project/path/to/serverless.yml
```

### Environment Variables

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_REGION`: Your AWS region 
- `SERVERLESS_ACCESS_KEY`: Your Serverless Framework access key
- `AWS_REGION`: Your AWS region (e.g., us-east-1)

## Important Notes

- The container will automatically detect and install Node.js dependencies if a `package.json` file exists in the same directory as your serverless.yml file.
- For AWS deployments, you need to provide AWS credentials or IAM role with sufficient permissions.
- The container will exit automatically after deployment completes.
