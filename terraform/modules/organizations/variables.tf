variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
  default     = ["ca-central-1"]
}
