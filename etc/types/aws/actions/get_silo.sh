#!/bin/bash
data=$($SILO_TYPE_DIR/cli/bin/aws s3api list-buckets --output json)
buckets=($(echo $data | 
  sed -e 's/[{}]/''/g' | 
    awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' |
      sed -n -e 's/^.*Name": //p' |
        grep flight-silo- |
          cut -d'"' -f2))
echo $buckets

for bucket in ${buckets[@]}; do
  can_access=$($SILO_TYPE_DIR/cli/bin/aws s3api head-bucket --bucket $bucket >/dev/null 2>&1; echo $?)
  if [ $can_access == 0 ]; then
    aws s3 cp s3://$bucket/cloud_metadata.yaml ./current_metadata.yaml >/dev/null
    name=$(cat ./current_metadata.yaml | grep name: | awk '{print $2}' | cut -d'"' -f2)
    rm ./current_metadata.yaml
    if [ $name == $SILO_NAME ]; then
      echo $bucket
      exit 0
    fi
  fi
done
