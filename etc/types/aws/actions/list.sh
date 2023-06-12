set -e

test $SILO_PUBLIC = true && sign_request=--no-sign-request || sign_request=""

files=$($SILO_TYPE_DIR/cli/bin/aws s3api list-objects-v2 --bucket "$SILO_NAME" --prefix "$SILO_PATH" --delimiter / --output text --query Contents[:].Key $sign_request)

directories=$($SILO_TYPE_DIR/cli/bin/aws s3api list-objects-v2 --bucket "$SILO_NAME" --prefix "$SILO_PATH" --delimiter / --output text --query CommonPrefixes[:].Prefix $sign_request)

echo "---"
if [ "$files" != null ]; then
  echo "files:"
  echo -e "$files" | sed 's/\t/\n- /g' | tail -n +2
fi
if [ "$directories" != "None" ]; then
  echo -e "dirs:"
  echo -e "- $directories" | sed 's/\t/\n- /g'
fi
