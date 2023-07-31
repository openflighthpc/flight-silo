set -e

TYPE_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

mkdir -p $TYPE_DIR/cli/bin

temp_dir=$(mktemp -d)
cd $temp_dir

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" -s
unzip -qq awscliv2.zip
./aws/install -i $TYPE_DIR/cli/aws_cli -b $TYPE_DIR/cli/bin
rm -rf $temp_dir

echo "Prepared"
