test $SILO_PUBLIC = "true" && sign_request=--no-sign-request || sign_request=""
test $SILO_RECURSIVE = "true" && recursive=--recursive || recursive=""
object_uri="s3://$SILO_NAME/$SILO_PATH"
$SILO_TYPE_DIR/cli/bin/aws s3 rm "$object_uri" $sign_request $recursive
