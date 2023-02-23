bucket=$1
prefix=$2
$flight_SILO_types/aws/cli/bin/aws s3api list-objects-v2 --bucket "$bucket" --no-sign-request --prefix "$prefix" --delimiter /
