resource "aws_apigatewayv2_api" "fast_food_api_gateway" {
  name          = "fast-food-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "fast_food_stage" {
  api_id = aws_apigatewayv2_api.fast_food_api_gateway.id
  name   = "$default"

  auto_deploy = true
}

resource "aws_apigatewayv2_vpc_link" "fast_food_vpc_link" {
  name               = "fast-food-vpc-link"
  security_group_ids = ["sg-0151b6176b2a24967"]
  subnet_ids         = ["subnet-0f926613dbccfe0c2", "subnet-07b6b037b3899e311"]

  tags = {
    Usage = "fast_food_vpc_link"
  }
}

resource "aws_apigatewayv2_integration" "fast_food_integration" {
  api_id    = aws_apigatewayv2_api.fast_food_api_gateway.id
  description      = "Example with a load balancer"
  integration_type = "HTTP_PROXY"
  integration_uri  = "arn:aws:elasticloadbalancing:us-east-1:372431383879:listener/app/fast-food-alb-fast-food-app/8d1788e68b9ac6f2/72e07562662a7d2b"

  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.fast_food_vpc_link.id
}

resource "aws_apigatewayv2_route" "fast_food_route" {
  api_id    = aws_apigatewayv2_api.fast_food_api_gateway.id
  route_key = "ANY /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.fast_food_integration.id}"
}

resource "aws_apigatewayv2_deployment" "example" {
  api_id      = aws_apigatewayv2_api.fast_food_api_gateway.id
  description = "Example deployment"

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.fast_food_integration),
      jsonencode(aws_apigatewayv2_route.fast_food_route),
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "aws_apigatewayv2_vpc_link" "example" {
  name               = "example"
  security_group_ids = ["sg-0a16be9fc90a09c1c"]
  subnet_ids         = ["subnet-0e0ee6471ade4a73a", "subnet-0fbce0f322dbb0df2"]

  tags = {
    Usage = "example"
  }
}

resource "aws_apigatewayv2_integration" "example" {
  api_id           = aws_apigatewayv2_api.example.id
  credentials_arn  = aws_iam_role.example.arn
  description      = "Example with a load balancer"
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.example.arn

  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.example.id

  tls_config {
    server_name_to_verify = "example.com"
  }

  request_parameters = {
    "append:header.authforintegration" = "$context.authorizer.authorizerResponse"
    "overwrite:path"                   = "staticValueForIntegration"
  }

  response_parameters {
    status_code = 403
    mappings = {
      "append:header.auth" = "$context.authorizer.authorizerResponse"
    }
  }

  response_parameters {
    status_code = 200
    mappings = {
      "overwrite:statuscode" = "204"
    }
  }
}*/