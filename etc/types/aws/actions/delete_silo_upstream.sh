set -e

bucket=$SILO_NAME
$SILO_TYPE_DIR/cli/bin/aws s3 rb s3://$bucket --force
