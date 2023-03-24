object_uri="s3://$SILO_NAME/$SILO_DEST"
$SILO_TYPE_DIR/cli/bin/aws s3 cp "$SILO_SOURCE" "$object_uri" $recursive
