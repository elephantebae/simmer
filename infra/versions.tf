terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state in S3 with native lockfiles (no DynamoDB lock table).
  # Settings live in backend.hcl (gitignored); see backend.hcl.example.
  # CI runs `terraform init -backend=false` for fmt/validate.
  backend "s3" {}
}
