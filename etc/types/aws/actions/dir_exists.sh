bucket=$1
key=${2:1}
region=$3
not_exist=$($flight_SILO_types/aws/cli/bin/aws s3api head-object --bucket "$bucket" --key "$key" --no-sign-request --region "$region">/dev/null 2>&1; echo $?)
if [ $not_exist == 254 ]; then
  echo "no"
else
  echo "yes"
fi
