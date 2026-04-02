provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "development"
      ManagedBy   = "terraform"
      Owner       = "aromaestro"
    }
  }
}
