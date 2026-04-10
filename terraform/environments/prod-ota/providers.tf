provider "aws" {
  region = "ca-central-1"

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Owner       = "aromaestro"
      Application = "ota"
    }
  }
}
