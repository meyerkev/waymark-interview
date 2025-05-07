# Make me a bucket that is non-public

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "meyerkev-waymark-interview-sample"

  # These all default to true, but I'm setting them explicitly to be explicit
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# So the OPTIMAL way to do this would be to do bucket upload via a bucket policy and external roles.  
# The significantly less optimal way is to do this the way I'm doing it here which is to make an IAM user
# and then use that user's credentials to upload to the bucket.  
# Since we don't have a cross-account role to play with, here we go. 

# In a more general sense, it might make sense to wrap a service or an API gateway in front this bucket to do that upload
# and also authenticate the upload.  
resource "aws_iam_user" "s3_uploader" {
  name = "waymark-s3-uploader-user"
}

resource "aws_iam_access_key" "s3_uploader_key" {
  user = aws_iam_user.s3_uploader.name
}

resource "aws_iam_user_policy" "s3_uploader_policy" {
  name = "s3-uploader-policy"
  user = aws_iam_user.s3_uploader.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          # Not ideal, but I'm using these creds to repeatedly upload 
          # the same file over and over again. 
          # So we `s3 rm` the file, then `s3 cp` the file
          "s3:DeleteObject"
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




