#!/bin/bash -e

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILE_NAME="parlay-generator-$TIMESTAMP.zip"

zip -r -qq "$FILE_NAME" src/main
echo "### Zipped $FILE_NAME successfully."

if aws lambda get-function --function-name ParlayGeneratorFunction; then
  echo "Updating lambda..."
  aws lambda update-function-code \
    --function-name ParlayGeneratorFunction \
    --zip-file fileb://"${FILE_NAME}"
else
  echo "### Creating lambda..."
  IAM_ROLES=$(aws iam list-roles)
  LAMBDA_EXECUTION_ROLE_ARN=$(echo "$IAM_ROLES" | jq -r '.Roles[] | select(.RoleName | contains("LambdaExecutionRole"))' | jq '.Arn' | tr -d '"')

  aws lambda create-function \
    --function-name ParlayGeneratorFunction \
    --runtime go1.x \
    --zip-file fileb://"${FILE_NAME}" \
    --handler main \
    --role "${LAMBDA_EXECUTION_ROLE_ARN}"
fi
