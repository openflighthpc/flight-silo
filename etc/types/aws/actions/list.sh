bucket=$1
prefix=${2:1}
export AWS_DEFAULT_REGION=$3
export AWS_ACCESS_KEY_ID=$4
export AWS_SECRET_ACCESS_KEY=$5
sign_request=$6
$flight_SILO_types/aws/cli/bin/aws s3api list-objects-v2 --bucket "$bucket" --prefix "$prefix" --delimiter / --output json $sign_request
