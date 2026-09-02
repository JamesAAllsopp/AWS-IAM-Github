terraform {
  backend "s3"  {
    bucket = "feov-lmvviar3k02ucclcr1u-state-bucket"
    key = "github-role-ecr"
    encrypt = true
    dynamodb_table = "feov-lmvviar3k02ucclcr1u-state-lock"
    region = "eu-west-2"
    #role_arn = "arn:aws:iam::851840518993:role/feov-lmvviar3k02ucclcr1u-tf-assume-role"
  }
}

provider "aws" {
  region = "eu-west-2"
}
