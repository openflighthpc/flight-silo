bucket=$1
prefix=${2:1}
region=$3
$flight_SILO_types/aws/cli/bin/aws s3api list-objects-v2 --bucket "$bucket" --no-sign-request --prefix "$prefix" --delimiter / --region "$region"
