OBJECT_URI="s3://$SILO_NAME/$SILO_DEST"

if $SILO_RECURSIVE ; then
  $SILO_TYPE_DIR/cli/bin/aws s3 cp $SILO_SOURCE $OBJECT_URI --recursive

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
  IFS='/' read -ra ADDR <<< ${SILO_DEST}

  KEY=''
  for i in "${ADDR[@]}"; do
    if [ "$i" == "${ADDR[0]}" ] || [ "$i" == "${ADDR[-1]}" ] || [ -z  "$i" ]; then
      continue
    fi

    KEY+="$i/"
    NEWKEY=${KEY#"$(basename $SILO_SOURCE)"}
    NEWKEY="${ADDR[0]}/$NEWKEY"

    $SILO_TYPE_DIR/cli/bin/aws s3api put-object --bucket $SILO_NAME --key "$NEWKEY"
  done

  $SILO_TYPE_DIR/cli/bin/aws s3 cp $SILO_SOURCE $OBJECT_URI
fi
