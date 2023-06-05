#!/bin/bash
data=$($SILO_TYPE_DIR/cli/bin/aws s3api list-buckets --output json)
buckets=($(echo $data |
  sed -e 's/[{}]/''/g' |
    awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' |
      sed -n -e 's/^.*Name": //p' |
        grep flight-silo- |
          cut -d'"' -f2))

for bucket in ${buckets[@]}; do
  can_access=$($SILO_TYPE_DIR/cli/bin/aws s3api head-bucket --bucket $bucket >/dev/null 2>&1; echo $?)
  if [ $can_access == 0 ]; then
    metadata=$($SILO_TYPE_DIR/cli/bin/aws s3 cp s3://$bucket/cloud_metadata.yaml -)
    name=$(echo "$metadata" | grep name: | awk '{print $2}' | cut -d'"' -f2)
    if [ $name == $SILO_NAME ]; then
      echo $bucket
      exit 0
    fi
  fi
done
