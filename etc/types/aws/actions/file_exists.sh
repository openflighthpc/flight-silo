test $SILO_PUBLIC = true && sign_request=--no-sign-request || sign_request=""
not_exist=$($SILO_TYPE_DIR/cli/bin/aws s3api head-object --bucket "$SILO_NAME" --key "$SILO_PATH" $sign_request --output json >/dev/null 2>&1; echo $?)

if [ $not_exist != 0 ]; then
  echo "no"
else
  echo "yes"
fi
