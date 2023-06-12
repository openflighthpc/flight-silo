set -e

bucket=$SILO_ID
$SILO_TYPE_DIR/cli/bin/aws s3 rb s3://$bucket