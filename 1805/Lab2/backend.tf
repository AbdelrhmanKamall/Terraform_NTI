terraform {
  backend "s3" {
    bucket = "terraform-ntibcukett"
    key = "statefile"
    region = "us-east-1"
    dynamodb_table = "table-lock-terraform"   
  }
}