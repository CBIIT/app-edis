
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  required_version = ">= 0.14.9"

  # define s3 configuration parameters in init cli command options
  # like: terraform init -backend-config="bucket=<s3bucket>" -backend-config="key=api-edis-tf-state/api-edis-dev2" -backend-config="region=us-east-1"
  #  backend "local" {
  #  }
}

provider "aws" {
  region = "us-east-1"
}
