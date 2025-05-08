# Make me a bucket that is non-public

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "meyerkev-waymark-interview-sample"

  # These all default to true, but I'm setting them explicitly to be explicit
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Own objects in the bucket
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # Setup policies for security
  attach_deny_incorrect_encryption_headers = true
  attach_require_latest_tls_policy = true

  # This _can_ be done adding the KMS key to the upload commands,
  # but it's not clear that it's a good idea unless our counterparties are 
  # really strict about this and really good at following it. 
  # 
  # attach_deny_incorrect_kms_key_sse = true
  # allowed_kms_key_arn = aws_kms_key.s3_upload_key.arn
  # attach_deny_unencrypted_object_uploads = true

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    # None of this is actually needed, but this is the
    # sort of thing that you could do on this bucket policy
    # to enable cross-account uploads.
    Statement = [
      {
        Sid = "AllowUploaderUser"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.s3_uploader.arn
        }
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Sid = "AllowLambdaAccess"
        Effect = "Allow"
        Principal = {
          AWS = module.lambda_function.lambda_role_arn
        }
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
        ]
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  # Add KMS encryption to the bucket
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3.arn
      }
    }
  }

}

resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3" {
  name          = "alias/s3-bucket-key"
  target_key_id = aws_kms_key.s3.id
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
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ],
      },
      {
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:CreateGrant",
        ]
        Resource = [
          aws_kms_key.s3.arn
        ],
      }
    ]
  })
}




