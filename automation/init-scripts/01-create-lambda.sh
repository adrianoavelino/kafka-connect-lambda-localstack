#!/bin/bash

echo "########### script 01 - Creating lambda function ###########"
awslocal cloudformation create-stack \
  --stack-name example-lambda-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-body file:///etc/localstack/init/ready.d/config/cloudformation.yml
echo "########### Lambda function created###########"

sleep 10
