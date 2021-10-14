provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "cyber94_test2_oabu_s3_bucket_tf" {
  bucket = "cyber94-oabu-bucket"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  acl = "private"

  tags = {
    Name = "cyber94_test2_oabu_s3_bucket"
  }
}


resource "aws_dynamodb_table" "cyber94_test2_oabu_dynamodb_table_lock_tf" {
  name = "cyber94_calculator_oabu_dynamodb_table_lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
