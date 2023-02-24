bucket=$1
object=$2
destination=$3
region=$4
$flight_SILO_types/aws/cli/bin/aws s3api get-object --bucket "$bucket" --key "$object" $destination --no-sign-request --region "$region"
