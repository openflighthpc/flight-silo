test $SILO_PUBLIC = true && sign_request=--no-sign-request || sign_request=""

files=$($SILO_TYPE_DIR/cli/bin/aws s3api list-objects-v2 --bucket "$SILO_NAME" --prefix "$SILO_PATH" --delimiter / --output json --query "Contents[?!(Key=='$SILO_PATH')].{ name: Key, size: Size}" $sign_request)

directories=$($SILO_TYPE_DIR/cli/bin/aws s3api list-objects-v2 --bucket "$SILO_NAME" --prefix "$SILO_PATH" --delimiter / --output json --query CommonPrefixes[:].Prefix $sign_request)

if [[ "$files" == "null" ]] ; then
  FILES=[]
else
  FILES=$files
fi

if [[ "$directories" == "null" ]] ; then
  DIRECTORIES=[]
else
  DIRECTORIES=$directories
fi

cat << EOF
{"files":$FILES,"directories":$DIRECTORIES}
EOF
