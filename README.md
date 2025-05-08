# Kevin Meyer's Waymark interview

Setting up a lambda bucket trigger with a lambda

## Install prerequisites

1. On OSX or Linux with brew: 

```shell
brew install awscli tfenv
cd terraform/
tfenv install
```

On Linux, I still recommend [tfenv](https://github.com/tfutils/tfenv)

2. configure aws with an IAM login that is an Administrator.  You don't have to be an admin, but I didn't do least access for the setup yet.  

```shell
aws configure

# You can also do this, but you'll need to export the DEFAULT_AWS_PROFILE environment variable in every shell
export DEFAULT_AWS_PROFILE=<A name>
aws configure --profile $DEFAULT_AWS_PROFILE
export AWS_PROFILE=$DEFAULT_AWS_PROFILE
```

## Initialize Terraform

1. Make an S3 bucket in the console to store your terraform state

```shell
TFSTATE_BUCKET=<My bucket>
aws s3api create-bucket --bucket ${TFSTATE_BUCKET?}
aws s3api put-bucket-encryption --bucket ${TFSTATE_BUCKET?} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" }
    }]
  }'

aws s3api put-public-access-block --bucket ${TFSTATE_BUCKET?} \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'
```

2. Follow these instructions to setup the actual lambda
```shell
# Your bucket name from above is in $TFSTATE_BUCKET

# The statefile path inside your bucket
export TFSTATE_KEY=<something>.tfstate
# The region your S3 bucket is in (Default: us-east-2)
export TFSTATE_REGION=us-east-2

# Use terraform
cd terraform/

# You'll need to set all 3 to get this working properly
make init
```

## Install the cluster
```shell
make plan
make apply
```

## Setup the uploads
In the cluster module, there will be a variety of outputs.  If you lost them, no worries; Just run `terraform apply` again or `terraform outputs` to get a print-out of the outputs.  

Your outputs will be something like this: 

```shell
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

aws_configure_command = <sensitive>
aws_s3_delete_command = "aws s3 rm s3://meyerkev-waymark-interview-sample/sample.txt"
aws_s3_upload_command = "echo 'sample text' > sample.txt && aws s3 rm s3://meyerkev-waymark-interview-sample/sample.txt && aws s3 cp sample.txt s3://meyerkev-waymark-interview-sample/sample.txt"
s3_bucket_arn = "arn:aws:s3:::meyerkev-waymark-interview-sample"
s3_bucket_name = "meyerkev-waymark-interview-sample"
s3_uploader_access_key = <sensitive>
s3_uploader_secret_key = <sensitive>
```

## Run an upload

Ideally open a new terminal and run this:

```shell
# Configure upload configuration
# This will set the AWS_PROFILE variable to use the IAM user
# Hence why we need to set the DEFAULT_AWS_PROFILE up above
# if we're not using the default profile 
eval $(make enable-uploads)

# Open Cloudwatch and Lambda monitoring
# TODO: I couldn't get the copy-pasted link for Cloudwatch to work natively so you'll have to click through to the log group /aws/lambda/waymark-s3-lambda-function
open "https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#logsV2:log-groups"
open "https://us-east-2.console.aws.amazon.com/lambda/home?region=us-east-2#/functions/waymark-s3-lambda-function?subtab=permissions&tab=monitoring"
```

Then to run the actual upload: 
```shell
# do the upload
make upload
```

This is idempotent and can be run over and over again.

Now you can watch the metrics and logs and ensure that every time you run this, you can see metrics and logs

## Turndown

```shell
make cleanup
```

or if it's an account you really really **do not** want to get charged for:

```shell
# Validate that your access key is in the aws-nuke ignorelist
brew install aws-nuke
aws-nuke run --config aws-nuke.yaml
```