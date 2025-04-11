terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  
  backend "s3" {
    bucket         = "ramki20-terraform-state-appconfig"
    key            = "feature-flags/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ramki20-terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}