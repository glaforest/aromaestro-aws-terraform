variable "api_keys" {
  description = "X-Api-Key sent by the IoT Lambdas, per target site: dev = dev.aromaestro.com, prod = AWS_IOT_LAMBDA_API_KEY of www.aromaestro.com. Stored only in gitignored prod-iot/iot.auto.tfvars."
  type = object({
    dev  = string
    prod = string
  })
  sensitive = true
}
