# terraform version
terraform {
  required_version = "= 0.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=3.12.0"
    }
  }
}

# aws region
provider "aws" {
  region = "ap-northeast-1"
}

locals {
  title    = "リブリーネット"
  app_name = "librinet"
  domain   = "${local.app_name}.jp"
  path     = "https://${local.domain}"
  bucket   = "${local.app_name}-tf"
}