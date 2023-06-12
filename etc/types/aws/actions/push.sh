OBJECT_URI="s3://$SILO_NAME/$SILO_DEST"

if $SILO_RECURSIVE ; then
  aws s3 cp $SILO_SOURCE $OBJECT_URI --recursive

  FILES=$(find "$SILO_SOURCE" -type d)
  while IFS= read -r line; do
    KEY=$(realpath --relative-to="$SILO_SOURCE/.." $line)

    KEY=${KEY#"$(basename $SILO_SOURCE)"}
    if [[ "$SILO_DEST" == */ ]] ; then
      SILO_DEST=${SILO_DEST%?}
    fi

    $SILO_TYPE_DIR/cli/bin/aws s3api put-object --bucket $SILO_NAME --key "$SILO_DEST$KEY/"
  done <<< "$FILES"
else
  aws s3 cp $SILO_SOURCE $OBJECT_URI
fi
