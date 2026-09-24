# terraform-aws-wafv2-web-acl

Terraform module for a WAFv2 web ACL — filters and rate-limits
requests to a CloudFront distribution or a regional resource (ALB, API
Gateway, AppSync, Cognito).

## Cost

WAF bills a flat monthly fee per web ACL, plus a per-rule monthly fee
and a per-million-requests charge for traffic it inspects — a managed
rule group in `rules_json` counts as one rule for this purpose. See
AWS's [WAF pricing](https://aws.amazon.com/waf/pricing/) page for
current rates.

## Design

`rules_json` takes the ACL's rules as a JSON array matching AWS's own
`wafv2` rule schema exactly, the same way
[`terraform-aws-ecs-service`](https://github.com/kn47ytv9mv/terraform-aws-ecs-service)
takes `container_definitions` as raw JSON — WAF's rule statements
nest arbitrarily deep (`and`/`or`/`not` compositions of byte-match,
regex, SQLi, XSS, geo-match, rate-based, and managed-rule-group
statements), and modeling that recursively in HCL would cost far more
complexity than it returns. This mirrors the AWS provider's own
`rule_json` escape hatch directly — validate a rule document against
the [WAF rule statement reference](https://docs.aws.amazon.com/waf/latest/APIReference/API_Rule.html)
rather than this module's own schema.

`default_action` defaults to `"block"`, the safer of the two — an ACL
with no rules and the default `"block"` rejects everything until a
rule in `rules_json` explicitly allows something, rather than silently
passing all traffic through.

For a `"REGIONAL"`-scope ACL, this module creates only the ACL itself,
not its attachment to an ALB or other regional resource — pair with
[`terraform-aws-wafv2-web-acl-association`](https://github.com/kn47ytv9mv/terraform-aws-wafv2-web-acl-association).
A `"CLOUDFRONT"`-scope ACL needs no separate association: pass this
module's `arn` output straight to
[`terraform-aws-cloudfront`](https://github.com/kn47ytv9mv/terraform-aws-cloudfront)'s
`web_acl_id`.

## Usage

A CloudFront-scoped ACL with an AWS managed rule group:

```hcl
module "web_acl" {
  source = "kn47ytv9mv/wafv2-web-acl/aws"

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
```

Or directly from this repository, a regional ACL for an ALB:

```hcl
module "web_acl" {
  source = "github.com/kn47ytv9mv/terraform-aws-wafv2-web-acl"

  scope          = "REGIONAL"
  default_action = "allow"

  visibility_config = {
    metric_name = "example-alb-acl"
  }
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | Name of the web ACL. If null, a unique name is generated. | `null` | no |
| description | A description of the web ACL. | `null` | no |
| scope | Where the web ACL applies: 'REGIONAL' (ALB, API Gateway, AppSync, Cognito — pair with terraform-aws-wafv2-web-acl-association) or 'CLOUDFRONT' (pass the arn output straight to terraform-aws-cloudfront's web_acl_id). | `null` | no |
| default_action | Action for a request that does not match any rule: 'allow' or 'block'. Defaults to the safer 'block' — an explicit allow rule is then needed for legitimate traffic, rather than an explicit block rule for bad traffic. | `"block"` | no |
| rules_json | The ACL's rules, as a JSON array matching AWS's own wafv2 rule schema exactly (managed rule groups, rate-based rules, custom byte/regex/SQLi/XSS match rules, and/or/not compositions). This mirrors the AWS provider's own rule_json escape hatch rather than modeling the rule block's arbitrarily deep statement nesting — see the Design section. If null, the ACL has no rules and every request falls through to default_action. | `null` | no |
| custom_response_bodies | Custom response bodies a rule or default_action can reference by key, for a block action that returns something other than AWS's own default response. | `[]` | no |
| visibility_config | CloudWatch metrics and sampled-request logging for the ACL overall. metric_name shows up in CloudWatch; sampled_requests_enabled captures a sample of matching requests, viewable in the console. | n/a | yes |
| tags | A map of tags to assign to the web ACL. | `null` | no |
| log_destination_configs | ARNs receiving request logs — a CloudWatch log group, S3 bucket, or Firehose stream whose name begins with `aws-waf-logs-`. Supplying a destination enables logging. The prefix is an AWS requirement, not a convention. | `[]` | no |
| redacted_header_names | Request header names whose values are replaced with `REDACTED` in the logs (e.g. `['authorization', 'cookie']`). | `[]` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the web ACL. |
| arn | The ARN of the web ACL — pass to terraform-aws-cloudfront's web_acl_id, or to terraform-aws-wafv2-web-acl-association's web_acl_arn for a regional resource. |
| capacity | The ACL's total consumed capacity units (WCUs) — AWS caps this per ACL; useful for staying under that ceiling as rules_json grows. |
| name | The name of the web ACL. |

## License

MIT — see [LICENSE.md](LICENSE.md).
