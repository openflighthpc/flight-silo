set -e

mkdir -p $flight_SILO_types/aws/cli/bin

temp_dir=$(mktemp -d)
cd $temp_dir

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" -s
unzip -qq awscliv2.zip
./aws/install -i $flight_SILO_types/aws/cli/bin/cli/aws_cli -b $flight_SILO_types/aws/cli/bin/
rm -rf $temp_dir

echo "Prepared"
