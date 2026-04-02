terraform {
  required_version = ">= 1.7.0"

  backend "s3" {
    bucket         = "aromaestro-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "aromaestro-terraform-locks"
    encrypt        = true
    profile        = "aromaestro-mgmt"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
