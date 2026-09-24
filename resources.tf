resource "random_uuid" "resource" {}

resource "aws_wafv2_web_acl" "resource" {
  name        = coalesce(var.name, random_uuid.resource.id)
  description = var.description
  scope       = var.scope
  rule_json   = var.rules_json

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "custom_response_body" {
    for_each = { for c in var.custom_response_bodies : c.key => c }

    content {
      key          = custom_response_body.value.key
      content      = custom_response_body.value.content
      content_type = custom_response_body.value.content_type
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.visibility_config.cloudwatch_metrics_enabled
    metric_name                = var.visibility_config.metric_name
    sampled_requests_enabled   = var.visibility_config.sampled_requests_enabled
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_logging_configuration" "resource" {
  count = length(var.log_destination_configs) > 0 ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.resource.arn
  log_destination_configs = var.log_destination_configs

  dynamic "redacted_fields" {
    for_each = var.redacted_header_names

    content {
      single_header {
        name = redacted_fields.value
      }
    }
  }
}

output "id" {
  description = "The ID of the web ACL."
  value       = aws_wafv2_web_acl.resource.id
}

output "name" {
  description = "The name of the web ACL."
  value       = aws_wafv2_web_acl.resource.name
}

output "arn" {
  description = "The ARN of the web ACL — pass to terraform-aws-cloudfront's web_acl_id, or to terraform-aws-wafv2-web-acl-association's web_acl_arn for a regional resource."
  value       = aws_wafv2_web_acl.resource.arn
}

output "capacity" {
  description = "The ACL's total consumed capacity units (WCUs) — AWS caps this per ACL; useful for staying under that ceiling as rules_json grows."
  value       = aws_wafv2_web_acl.resource.capacity
}
