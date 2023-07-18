set -e

test $SILO_PUBLIC = "true" && sign_request=--no-sign-request || sign_request=""
test $SILO_RECURSIVE = "true" && recursive=--recursive || recursive=""
object_uri="s3://$SILO_NAME/$SILO_SOURCE"
destination=${SILO_DEST:=/dev/stdout}
$SILO_TYPE_DIR/cli/bin/aws s3 cp "$object_uri" "$destination" $sign_request $recursive --quiet
