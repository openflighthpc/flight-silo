bucket=$1
key=${2:1}
export AWS_DEFAULT_REGION=$3
export AWS_ACCESS_KEY_ID=$4
export AWS_SECRET_ACCESS_KEY=$5
sign_request=$6
not_exist=$($flight_SILO_types/aws/cli/bin/aws s3api head-object --bucket "$bucket" --key "$key" --region "$region" $6 >/dev/null 2>&1; echo $?)
if [ $not_exist == 254 ]; then
  echo "no"
else
  echo "yes"
fi
