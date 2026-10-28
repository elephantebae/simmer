provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "simmer"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
