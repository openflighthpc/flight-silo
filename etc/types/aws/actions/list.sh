bucket=$1
test $2 = true && sign_request=--no-sign-request || sign_request=""
prefix=${3:1}
export AWS_DEFAULT_REGION=$4
export AWS_ACCESS_KEY_ID=$5
export AWS_SECRET_ACCESS_KEY=$6
files=$($flight_SILO_types/aws/cli/bin/aws s3api list-objects-v2 --bucket "$bucket" --prefix "$prefix" --delimiter / --output yaml --query Contents[:].Key $sign_request)
dirs=$($flight_SILO_types/aws/cli/bin/aws s3api list-objects-v2 --bucket "$bucket" --prefix "$prefix" --delimiter / --output yaml --query CommonPrefixes[:].Prefix $sign_request)
echo "---"
if [ "$files" != null ]; then
  echo "files:"
  echo -e "$files" | tail -n +2
fi
if [ "$dirs" != null ]; then
  echo "dirs:"
  echo -e "$dirs"
fi
