terraform {
  backend "s3" {
    # The key is supplied per estate by the workflow that runs Terraform:
    #   -backend-config="key=estates/<name_suffix>/terraform.tfstate"
    bucket       = "xd-tfstate-838029585209"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = "~> 1.15"
}

provider "aws" {
  region = "eu-west-1"

  # The account tags every resource with the identity that created it. That tag is
  # not in this configuration, so without this block Terraform plans to remove it
  # from every resource on every run, forever, and no plan is ever clean.
  ignore_tags {
    keys = ["CreatorName"]
  }

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}
