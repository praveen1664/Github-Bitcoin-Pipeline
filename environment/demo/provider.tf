terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  /* profile = "default"
  region = "us-east-1" */

}

 terraform {
   backend "s3" {
     bucket = "praveen-terraform-state"
     key    = "Github-Bitcoin-Pipeline/GitHUBACtions_CI_DOCKER_ECR_ECS_EFS"
     region = "us-east-1"
   }
 }