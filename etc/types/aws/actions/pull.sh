object_uri="s3://$1$2"
destination=$3
export AWS_DEFAULT_REGION=$4
export AWS_ACCESS_KEY_ID=$5
export AWS_SECRET_ACCESS_KEY=$6
recursive=$7
$flight_SILO_types/aws/cli/bin/aws s3 cp "$object_uri" "$destination" $recursive
