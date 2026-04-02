provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::315466292610:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      Environment = "logarchive"
      ManagedBy   = "terraform"
      Owner       = "aromaestro"
    }
  }
}
