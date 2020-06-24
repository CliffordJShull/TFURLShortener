# Top level rest api
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
 resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
   resource_id = aws_api_gateway_method.proxy.resource_id
   http_method = aws_api_gateway_method.proxy.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.tfurlshortener.invoke_arn
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
    "text/html" = <<EOF
    <!DOCTYPE html>
    <html itemtype="http://schema.org/WebPage" lang="en">
    <head>
    <meta charset="utf-8"/>
    <title>
        Tiny URL
    </title>
    </head>
    <body>
    <script src="https://code.jquery.com/jquery-3.2.1.min.js" integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4=" crossorigin="anonymous"></script>
    <script type="text/javascript">
    $(document).ready(function() {
        $('#submit').click(function(e) {
            e.preventDefault();
     
            var urlData = $('#urltext').val();
            var apiKey = $('#apikey').val();
            var headersData = {'X-Api-Key': apiKey, 'url': urlData};
     
            $.ajax({
                type: "POST",
                url: window.location.pathname,
                headers: headersData,
                contentType: "application/json; charset=utf-8",
                dataType: 'text',
                success: function(response) {
                  var hlink = '<a href="' + response + '" target="_blank">' + response + '</a>';
                  $('#link').html(hlink);
                  //alert('Your tiny URL has been generated and is shown under "Output"');
                },
                error: function(xhr, ajaxOptions, thrownError) {
                    var rbody = xhr.responseJSON
                    if(xhr.status==403) {
                        alert('You shall not pass!');
                    } else if(xhr.status==400) {
                        alert('Something\'s amiss... Try again.');
                    } else if(xhr.status==429 && rbody.message=="Limit Exceeded") {
                        alert('You have exceeded the number of requests today.  Try again tomorrow.')
                    } else if(xhr.status==429) {
                        alert('You need to slowwwwww dowwwwwwwwn.')
                    } else {
                        alert('What did you break?');
                    }
                }
            });
        });
    });
    </script>
     
    <h1>Tiny URL</h1>
    <textarea id="urltext" rows="8" cols="100" maxlength="400000" autocomplete="off" required autofocus></textarea>
    <br/><br/>
    <b>API Key:</b>
    <textarea id="apikey" rows="1" cols="50" maxlength="50" required></textarea>
    <br/><br/>
    <button id="submit">Shrink It!</button>
    <br/><br/>
    <h2>Output:</h2>
    <div id="link">Your tiny URL will appear here after you Shrink It!</div>
    </body>
    </html>
    EOF
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
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root_GET,
     aws_api_gateway_integration.lambda_root_POST
   ]

   rest_api_id = aws_api_gateway_rest_api.tfurlshortener.id
   stage_name  = "test"
 }

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

# Returns api gw invoke url for testing
output "base_url" {
  value = aws_api_gateway_deployment.tfurlshortener.invoke_url
}
