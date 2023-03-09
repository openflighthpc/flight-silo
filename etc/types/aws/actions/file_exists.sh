bucket=$1
test $2 = true && sign_request=--no-sign-request || sign_request=""
key=${3:1}
export AWS_DEFAULT_REGION=$4
export AWS_ACCESS_KEY_ID=$5
export AWS_SECRET_ACCESS_KEY=$6
not_exist=$($flight_SILO_types/aws/cli/bin/aws s3api head-object --bucket "$bucket" --key "$key" $sign_request --output json >/dev/null 2>&1; echo $?)
if [ $not_exist == 254 ]; then
  echo "no"
else
  echo "yes"
fi
