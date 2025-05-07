output "s3_bucket_name" {
  value = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

output "s3_uploader_access_key" {
  value     = aws_iam_access_key.s3_uploader_key.id
  sensitive = true
}

output "s3_uploader_secret_key" {
  value     = aws_iam_access_key.s3_uploader_key.secret
  sensitive = true
}

# Create a profile waymark-interview-sample
output "aws_configure_command" {
  value = <<EOF
aws configure --profile waymark-interview-sample set region ${var.aws_region};
aws configure --profile waymark-interview-sample set aws_access_key_id ${aws_iam_access_key.s3_uploader_key.id};
aws configure --profile waymark-interview-sample set aws_secret_access_key ${aws_iam_access_key.s3_uploader_key.secret};
aws configure --profile waymark-interview-sample set output json;
export AWS_PROFILE=waymark-interview-sample;
EOF

  sensitive = true
}

output "aws_s3_upload_command" {
  value = "echo 'sample text' > sample.txt && aws s3 rm s3://${module.s3_bucket.s3_bucket_id}/sample.txt && aws s3 cp sample.txt s3://${module.s3_bucket.s3_bucket_id}/sample.txt"
}

output "aws_s3_delete_command" {
  value = "aws s3 rm s3://${module.s3_bucket.s3_bucket_id}/sample.txt"
}

output "aws_s3_delete_all_command" {
  value = "scripts/empty-s3-bucket.sh ${module.s3_bucket.s3_bucket_id}"
}


