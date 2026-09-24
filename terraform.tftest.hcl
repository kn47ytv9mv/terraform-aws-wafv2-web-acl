mock_provider "aws" {
}

run "scope_invalid_rejected" {
  command = plan

  variables {
    scope = "SIDEWAYS"
    visibility_config = {
      metric_name = "example-acl"
    }
  }

  expect_failures = [var.scope]
}

run "default_action_invalid_rejected" {
  command = plan

  variables {
    scope          = "REGIONAL"
    default_action = "SIDEWAYS"
    visibility_config = {
      metric_name = "example-acl"
    }
  }

  expect_failures = [var.default_action]
}

run "default_action_block_renders_block" {
  command = plan

  variables {
    scope = "REGIONAL"
    visibility_config = {
      metric_name = "example-acl"
    }
  }

  assert {
    condition     = length(aws_wafv2_web_acl.resource.default_action[0].block) == 1
    error_message = "default_action left at its default ('block') should render a block block."
  }

  assert {
    condition     = length(aws_wafv2_web_acl.resource.default_action[0].allow) == 0
    error_message = "default_action of 'block' should not render an allow block."
  }
}

run "default_action_allow_renders_allow" {
  command = plan

  variables {
    scope          = "CLOUDFRONT"
    default_action = "allow"
    visibility_config = {
      metric_name = "example-acl"
    }
  }

  assert {
    condition     = length(aws_wafv2_web_acl.resource.default_action[0].allow) == 1
    error_message = "default_action = 'allow' should render an allow block."
  }

  assert {
    condition     = length(aws_wafv2_web_acl.resource.default_action[0].block) == 0
    error_message = "default_action of 'allow' should not render a block block."
  }
}

run "rules_json_passes_through" {
  command = plan

  variables {
    scope = "REGIONAL"
    rules_json = jsonencode([
      {
        Name     = "rate-limit"
        Priority = 0
        Action   = { Block = {} }
        Statement = {
          RateBasedStatement = {
            Limit            = 2000
            AggregateKeyType = "IP"
          }
        }
        VisibilityConfig = {
          CloudWatchMetricsEnabled = true
          MetricName               = "rate-limit"
          SampledRequestsEnabled   = true
        }
      }
    ])
    visibility_config = {
      metric_name = "example-acl"
    }
  }

  assert {
    condition     = jsondecode(aws_wafv2_web_acl.resource.rule_json)[0].Name == "rate-limit"
    error_message = "rules_json should pass through unchanged."
  }
}

run "custom_response_bodies_render" {
  command = plan

  variables {
    scope = "REGIONAL"
    custom_response_bodies = [
      {
        key          = "blocked"
        content      = "Request blocked."
        content_type = "TEXT_PLAIN"
      }
    ]
    visibility_config = {
      metric_name = "example-acl"
    }
  }

  assert {
    condition     = length(aws_wafv2_web_acl.resource.custom_response_body) == 1
    error_message = "One custom_response_bodies entry should render exactly one custom_response_body block."
  }

  assert {
    condition     = anytrue([for c in aws_wafv2_web_acl.resource.custom_response_body : c.key == "blocked"])
    error_message = "custom_response_body.key should pass through unchanged."
  }
}

run "visibility_config_passes_through" {
  command = plan

  variables {
    scope = "REGIONAL"
    visibility_config = {
      metric_name                = "example-acl-metric"
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
    }
  }

  assert {
    condition     = aws_wafv2_web_acl.resource.visibility_config[0].metric_name == "example-acl-metric"
    error_message = "visibility_config.metric_name should pass through unchanged."
  }

  assert {
    condition     = aws_wafv2_web_acl.resource.visibility_config[0].cloudwatch_metrics_enabled == false
    error_message = "visibility_config.cloudwatch_metrics_enabled should pass through unchanged."
  }
}

run "no_logging_by_default" {
  command = plan

  variables {
    scope = "REGIONAL"
    visibility_config = {
      metric_name = "example-acl"
    }
  }

  assert {
    condition     = length(aws_wafv2_web_acl_logging_configuration.resource) == 0
    error_message = "Leaving log_destination_configs empty should create no logging configuration."
  }
}

run "supplying_a_destination_enables_logging" {
  command = plan

  variables {
    scope = "REGIONAL"
    visibility_config = {
      metric_name = "example-acl"
    }
    log_destination_configs = ["arn:aws:logs:us-east-1:123456789012:log-group:aws-waf-logs-app"]
  }

  assert {
    condition     = length(aws_wafv2_web_acl_logging_configuration.resource) == 1
    error_message = "Supplying a destination should create exactly one logging configuration."
  }
}

run "redacted_headers_create_one_block_each" {
  command = plan

  variables {
    scope = "REGIONAL"
    visibility_config = {
      metric_name = "example-acl"
    }
    log_destination_configs = ["arn:aws:logs:us-east-1:123456789012:log-group:aws-waf-logs-app"]
    redacted_header_names   = ["authorization", "cookie"]
  }

  assert {
    condition     = length(aws_wafv2_web_acl_logging_configuration.resource[0].redacted_fields) == 2
    error_message = "Each redacted header name should produce one redacted_fields block."
  }
}

run "readme_cloudfront_example" {
  command = plan

  variables {
    scope = "CLOUDFRONT"
    rules_json = jsonencode([
      {
        Name           = "aws-managed-common"
        Priority       = 0
        OverrideAction = { None = {} }
        Statement = {
          ManagedRuleGroupStatement = {
            VendorName = "AWS"
            Name       = "AWSManagedRulesCommonRuleSet"
          }
        }
        VisibilityConfig = {
          CloudWatchMetricsEnabled = true
          MetricName               = "aws-managed-common"
          SampledRequestsEnabled   = true
        }
      }
    ])
    visibility_config = {
      metric_name = "example-acl"
    }
  }
}

run "readme_regional_example" {
  command = plan

  variables {
    scope          = "REGIONAL"
    default_action = "allow"
    visibility_config = {
      metric_name = "example-alb-acl"
    }
  }
}
