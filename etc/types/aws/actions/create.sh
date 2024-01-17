set -e

bucket=$SILO_ID
$SILO_TYPE_DIR/cli/bin/aws s3 mb s3://$bucket
$SILO_TYPE_DIR/cli/bin/aws s3api put-object --bucket $bucket --key files/
$SILO_TYPE_DIR/cli/bin/aws s3api put-object --bucket $bucket --key projects/
$SILO_TYPE_DIR/cli/bin/aws s3api put-object --bucket $bucket --key software/
printf -- "---\nname: \"$SILO_NAME\"\ndescription:\nis_public: false\n" > "/tmp/${SILO_ID}_cloud_md.yaml"
$SILO_TYPE_DIR/cli/bin/aws s3api put-object --bucket $bucket --key cloud_metadata.yaml --body "/tmp/${SILO_ID}_cloud_md.yaml"
rm -f "/tmp/${SILO_ID}_cloud_md.yaml"
