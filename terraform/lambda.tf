module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "waymark-s3-lambda-function"
  handler       = "lambda-function.handler"
  runtime       = "python3.11"

  source_path = "${path.module}/lambda-src/lambda-function.py"

  # Add IAM policy to allow Lambda to read from S3
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:HeadObject",
          # You wouldn't think that HeadObject would mandate GetObject, but it does.
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3_bucket.s3_bucket_id

  lambda_function {
    lambda_function_arn = module.lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# Permission for S3 to invoke the Lambda
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bucket.s3_bucket_arn
}