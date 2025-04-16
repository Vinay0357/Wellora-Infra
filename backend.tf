# wellora-infra/backend.tf

terraform {
  backend "s3" {
    bucket         = "wellora-tfstate-bucket-unique-name" # REPLACE with your unique S3 bucket name
    key            = "global/wellora-infra/terraform.tfstate" # Path within the bucket for the state file
    region         = var.aws_region # Region where the S3 bucket exists
    encrypt        = true             # Encrypt the state file
    dynamodb_table = "wellora-tfstate-lock" # Optional: DynamoDB table for state locking (RECOMMENDED)
  }
}
