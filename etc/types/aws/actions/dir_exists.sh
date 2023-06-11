test $SILO_PUBLIC = "true" && sign_request=--no-sign-request || sign_request=""
list=$($SILO_TYPE_DIR/cli/bin/aws s3 ls s3://$SILO_NAME/$SILO_PATH $sign_request)

if [ -z "$list" ]; then
  echo "no"
else
  echo "yes"
fi
