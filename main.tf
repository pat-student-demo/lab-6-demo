terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

module "app_infra" {
  for_each = toset(["foo", "bar"])
  source = "./app_infra"
  app_name = each.key
}

