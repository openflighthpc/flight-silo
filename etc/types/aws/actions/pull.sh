object_uri="s3://$1$3"
test $2 = true && sign_request=--no-sign-request || sign_request=""
destination=$4
test $5 = true && recursive=--recursive || recursive=""
export AWS_DEFAULT_REGION=$6
export AWS_ACCESS_KEY_ID=$7
export AWS_SECRET_ACCESS_KEY=$8
$flight_SILO_types/aws/cli/bin/aws s3 cp "$object_uri" "$destination" $sign_request $recursive
