terraform {
  backend "s3" {
    bucket         = "ecommerce-tf-state-250516"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "ecommerce-terraform-locks"
    encrypt        = true
  }
}
