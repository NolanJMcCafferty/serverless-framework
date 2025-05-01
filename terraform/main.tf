provider "aws" {
  region = "{{ $sys.deploymentCell.region }}"
}

# Get the API Gateway endpoint frm the Serverless Framework deployment
data "aws_apigatewayv2_apis" "all_apis" {
  protocol_type = "HTTP"
}

locals {
  api_ids_list = tolist(data.aws_apigatewayv2_apis.all_apis.ids)
}

data "aws_apigatewayv2_api" "api_details" {
  count  = length(local.api_ids_list)
  api_id = local.api_ids_list[count.index]
}

# Find the API ID that matches the Serverless Job Deployment
locals {
  matching_api_id = [
    for api in data.aws_apigatewayv2_api.api_details : api.id
    if api.name == "{{ $var.serverless_service_name }}"
  ][0]
}

data "aws_apigatewayv2_api" "example" {
  api_id = local.matching_api_id
}

output "api_gateway_endpoint" {
  value = "${data.aws_apigatewayv2_api.example.api_endpoint}/hello"
}
