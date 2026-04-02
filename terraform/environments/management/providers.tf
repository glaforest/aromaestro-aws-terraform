provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "management"
      ManagedBy   = "terraform"
      Owner       = "aromaestro"
    }
  }
}
