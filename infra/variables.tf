variable "region" {
  description = "AWS region for every Simmer resource (Bedrock Claude models are available here)."
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment. Only dev exists until the MVP ships."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "monthly_budget_usd" {
  description = "Monthly AWS spend that triggers the budget alarm."
  type        = number
  default     = 5
}

variable "budget_alert_email" {
  description = "Where budget alarms go. Set in terraform.tfvars (gitignored), never committed."
  type        = string
  sensitive   = true
}

variable "state_bucket" {
  description = "Name of the Terraform state bucket (created outside Terraform). Set in terraform.tfvars / TF_VAR_state_bucket."
  type        = string
}
