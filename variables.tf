variable "name" {
  default     = null
  description = "Name of the web ACL. If null, a unique name is generated."
}

variable "description" {
  default     = null
  description = "A description of the web ACL."
}

variable "scope" {
  default     = null
  description = "Where the web ACL applies: 'REGIONAL' (ALB, API Gateway, AppSync, Cognito — pair with terraform-aws-wafv2-web-acl-association) or 'CLOUDFRONT' (pass the arn output straight to terraform-aws-cloudfront's web_acl_id)."

  validation {
    condition     = var.scope == null || contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be 'REGIONAL' or 'CLOUDFRONT'."
  }
}

variable "default_action" {
  default     = "block"
  description = "Action for a request that does not match any rule: 'allow' or 'block'. Defaults to the safer 'block' — an explicit allow rule is then needed for legitimate traffic, rather than an explicit block rule for bad traffic."

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "default_action must be 'allow' or 'block'."
  }
}

variable "rules_json" {
  default     = null
  description = "The ACL's rules, as a JSON array matching AWS's own wafv2 rule schema exactly (managed rule groups, rate-based rules, custom byte/regex/SQLi/XSS match rules, and/or/not compositions). This mirrors the AWS provider's own rule_json escape hatch rather than modeling the rule block's arbitrarily deep statement nesting — see the Design section. If null, the ACL has no rules and every request falls through to default_action."
}

variable "custom_response_bodies" {
  default     = []
  description = "Custom response bodies a rule or default_action can reference by key, for a block action that returns something other than AWS's own default response."
  type = list(object({
    key          = string
    content      = string
    content_type = string
  }))
}

variable "visibility_config" {
  description = "CloudWatch metrics and sampled-request logging for the ACL overall. metric_name shows up in CloudWatch; sampled_requests_enabled captures a sample of matching requests, viewable in the console."
  type = object({
    cloudwatch_metrics_enabled = optional(bool, true)
    metric_name                = string
    sampled_requests_enabled   = optional(bool, true)
  })
}

variable "log_destination_configs" {
  default     = []
  description = "ARNs receiving this web ACL's request logs — a CloudWatch log group whose name begins with 'aws-waf-logs-', an S3 bucket with the same prefix, or a Kinesis Firehose delivery stream. Supplying a destination enables logging automatically. The naming prefix is an AWS requirement, not a convention: a destination named otherwise is rejected. If empty, requests are not logged."
}

variable "redacted_header_names" {
  default     = []
  description = "Request header names whose values are replaced with REDACTED in the logs, for headers carrying credentials or personal data (e.g. ['authorization', 'cookie']). Names are matched case-insensitively."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the web ACL."
}
