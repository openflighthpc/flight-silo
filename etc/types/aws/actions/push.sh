OBJECT_URI="s3://$SILO_NAME/$SILO_DEST"

if $SILO_RECURSIVE ; then
  aws cp $SILO_SOURCE $OBJECT_URI --recursive
  FILES=$(find $SILO_SOURCE -type d)
  while IFS= read -r line; do
    KEY=$(realpath --relative-to="$SILO_SOURCE/.." $line)
    $SILO_TYPE_DIR/cli/bin/aws s3api put-object --bucket $bucket --key "$SILO_DEST/$KEY"
  done <<< "$FILES"
else
  aws cp $SILO_SOURCE $OBJECT_URI
fi
