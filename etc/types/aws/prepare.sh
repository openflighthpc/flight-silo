mkdir -p $PWD/cli/bin
install_dir=$PWD/cli
cd $(mktemp -d)

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install -i $install_dir/aws_cli -b $install_dir/bin
rm -rf $PWD

echo "AWS CLI prepared"
