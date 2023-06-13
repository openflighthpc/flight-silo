set -e

test $SILO_PUBLIC = "true" && sign_request=--no-sign-request || sign_request=""
object_uri="s3://$SILO_NAME/$SILO_SOURCE"
$SILO_TYPE_DIR/cli/bin/aws s3 cp "$object_uri" -  $sign_request $recursive
