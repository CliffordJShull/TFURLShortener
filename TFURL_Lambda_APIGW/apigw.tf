# Top level rest api creation
resource "aws_api_gateway_rest_api" "tfurlshortener" {
  name        = "tfurlshortener"
  description = "Terraform URLShortener"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Proxy resource
resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
   parent_id   = aws_api_gateway_rest_api.tfurlshortener.root_resource_id
   path_part   = "{proxy+}"
}

# Method for proxy resource
resource "aws_api_gateway_method" "proxy" {
   rest_api_id   = aws_api_gateway_rest_api.tfurlshortener.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "ANY"
   authorization = "NONE"
 }

# Integration for proxy resource
 resource "aws_api_gateway_integration" "lambda_proxy" {
   rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
   resource_id = aws_api_gateway_method.proxy.resource_id
   http_method = aws_api_gateway_method.proxy.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.tfurlshortener_redirect.invoke_arn
 }

# Root "/" method GET
  resource "aws_api_gateway_method" "proxy_root_GET" {
   rest_api_id   = aws_api_gateway_rest_api.tfurlshortener.id
   resource_id   = aws_api_gateway_rest_api.tfurlshortener.root_resource_id
   http_method   = "GET"
   authorization = "NONE"
 }

# Root "/" method GET integration
 resource "aws_api_gateway_integration" "lambda_root_GET" {
   rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
   resource_id = aws_api_gateway_method.proxy_root_GET.resource_id
   http_method = aws_api_gateway_method.proxy_root_GET.http_method
   type                    = "MOCK"
   
   request_templates = {
     "application/json" = <<EOF
     {
       "statusCode": 200
     }
     EOF
  }
 }

 # Root "/" method GET integration response
 resource "aws_api_gateway_integration_response" "proxy_root_int_response" {
  rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
  resource_id = aws_api_gateway_rest_api.tfurlshortener.root_resource_id
  http_method = aws_api_gateway_method.proxy_root_GET.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  # Transforms the backend JSON response to HTML w/JS
  response_templates = {
    "text/html" = "${file("/projects/terraform/TFURLShortener/MOCK_body_mapping.template")}"
  }
 }

# Root "/" method GET method response
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
  resource_id = aws_api_gateway_rest_api.tfurlshortener.root_resource_id
  http_method = aws_api_gateway_method.proxy_root_GET.http_method
  status_code = "200"

  response_models = {
     "text/html" = "Empty"
  }
}

# Root "/" method POST
resource "aws_api_gateway_method" "proxy_root_POST" {
   rest_api_id   = aws_api_gateway_rest_api.tfurlshortener.id
   resource_id   = aws_api_gateway_rest_api.tfurlshortener.root_resource_id
   http_method   = "POST"
   authorization = "NONE"
   api_key_required = true
   request_parameters = {"method.request.header.x-api-key" = true}
 }

 # Root "/" method POST integration
 resource "aws_api_gateway_integration" "lambda_root_POST" {
   rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
   resource_id = aws_api_gateway_method.proxy_root_POST.resource_id
   http_method = aws_api_gateway_method.proxy_root_POST.http_method
   
   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.tfurlshortener.invoke_arn
}

# Deploy the API
 resource "aws_api_gateway_deployment" "tfurlshortener" {
   depends_on = [
     aws_api_gateway_integration.lambda_proxy,
     aws_api_gateway_integration.lambda_root_GET,
     aws_api_gateway_integration.lambda_root_POST
   ]

   rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
   stage_name  = "test"
 }

### Post-Deployment actions
# Set logging settings
resource "aws_api_gateway_method_settings" "logging_setup" {
  depends_on = [
    aws_api_gateway_deployment.tfurlshortener
  ]
  rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
  stage_name  = "test"
  method_path = "*/*"
  settings {
    logging_level = "INFO"
    data_trace_enabled = true
    metrics_enabled = false
  }
}

# Create Usageplan
resource "aws_api_gateway_usage_plan" "tfurlshortener_usageplan" {
  name = "tfurlshortener_usageplan"

  api_stages {
    api_id = aws_api_gateway_rest_api.tfurlshortener.id
    stage  = aws_api_gateway_deployment.tfurlshortener.stage_name
  }
}

# Create API Key
resource "aws_api_gateway_api_key" "tfurlshortener_apikey" {
  name = "tfurlshortener_apikey"
}

# Add Usage Plan and API/Stage to API Key
resource "aws_api_gateway_usage_plan_key" "tfurlshortener_addusageplan" {
  key_id        = aws_api_gateway_api_key.tfurlshortener_apikey.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.tfurlshortener_usageplan.id
}

# Returns api gw invoke url for testing
output "base_url" {
  value = aws_api_gateway_deployment.tfurlshortener.invoke_url
}

output "api_key" {
  value = aws_api_gateway_api_key.tfurlshortener_apikey.value
}