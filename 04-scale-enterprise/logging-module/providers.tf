terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0, < 6.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
