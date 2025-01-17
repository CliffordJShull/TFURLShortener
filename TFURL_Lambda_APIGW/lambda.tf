 # Lambda integration for API GW ROOT "/" resource POST
 resource "aws_lambda_function" "tfurlshortener" {
   function_name = "TFURLShortener"

   # Local file for lambda code
   filename = "/projects/terraform/TFURLShortener/TFURL_Lambda_APIGW/tfurlshortener.zip"
   #filename = "lambdacode.zip"

   # "main" is the filename within the zip file (main.js) and "handler"
   handler = "tfurlshortener.handler"
   runtime = "nodejs10.x"

   role = "arn:aws:iam::886250118602:role/service-role/basic-lambda-execute-role"
 }

# Lambda integration for PROXY resource ANY
  resource "aws_lambda_function" "tfurlshortener_redirect" {
   function_name = "TFURLShortener_redirect"

   # Local file for lambda code
   filename = "/projects/terraform/TFURLShortener/TFURL_Lambda_APIGW/tfurlshortener_redirect.zip"

   # "main" is the filename within the zip file (main.js) and "handler"
   # is the name of the property under which the handler function was
   # exported in that file.
   handler = "tfurlshortener_redirect.handler"
   runtime = "nodejs10.x"

   role = "arn:aws:iam::886250118602:role/service-role/basic-lambda-execute-role"
   #role = "basic-lambda-execute-role"
 }

 # Setting json for assume role policy used in aws_iam_role resource below
data "aws_iam_policy_document" "trust-assume-role-policy" {
   statement {

   actions = ["sts:AssumeRole"]

   principals {
     type        = "Service"
     identifiers = ["lambda.amazonaws.com"]
   }  
  }
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
 resource "aws_iam_role" "tf-urlshortener-sts" {
   name = "tf-urlshortener-sts"
   assume_role_policy = data.aws_iam_policy_document.trust-assume-role-policy.json
 }

# add apigw invoke to lambda for ROOT "/" POST
 resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.tfurlshortener.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.tfurlshortener.execution_arn}/*/*"
 }

# add apigw invoke to lambda for PROXY ANY
 resource "aws_lambda_permission" "apigw_redirect" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.tfurlshortener_redirect.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.tfurlshortener.execution_arn}/*/*"
 }
 