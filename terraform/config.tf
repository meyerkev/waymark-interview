# hardcoding tf version purely because it's an interview
terraform {
  required_version = "1.11.4"
  backend "s3" {
    bucket = "meyerkev-terraform-state"
    key = "waymark-interview.tfstate"
    region = "us-east-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Latest is 5.97.0 as of 6 May 2025
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Terraform = "true"
    }
  }
}