provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "example-github-debugging-tf-state"
    key = "example-dev.tfstate"
    region = "us-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

module "github-debugging" {
  source = "../../app"
  
  env_name = "dev"
  project_name = "github-debugging"
}

module "ci-tf" {
  source = "../../ci-tf"

  env_name = "dev"
  project_name = "github-debugging"

  lambdas_s3_state_bucket = "example-github-debugging-tf-state"
  github_debugging_lambdas_s3_state = "example-dev.tfstate"
}