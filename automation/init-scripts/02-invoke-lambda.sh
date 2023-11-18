#!/bin/bash
echo "########### script 02 - Invoking the lambda function ###########"
awslocal lambda invoke --function-name example-function \
--payload '{"value": "my example"}' --output text result.txt

cat result.txt
echo "########### script 02 - Lambda function invoked ###########"
