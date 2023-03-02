object_uri="s3://$1$2"
destination=$3
region=$4
recursive=$5
$flight_SILO_types/aws/cli/bin/aws s3 cp "$object_uri" "$destination" --no-sign-request --region "$region" $5
