# Terraform AWS Free Tier

> Getting started with the Terraform for managing a base free-tier AWS resources.

### Project description

This is a [Terraform](https://www.terraform.io/) project for managing AWS resources. 

It can build the next infrastructure:

* [VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
* Public [Subnet](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-vpcs.html#AddaSubnet) in the `VPC`
* [IGW](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html) to enable access to or from the Internet for `VPC`
* [Route Table](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html) to associate `IGW`, `VPC` and `Subnet`
* [EC2 Instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html) in the public `Subnet` with the HTTP(s) & SSH access

### Pre steps

1. Install software
   * MACOS 
 ```shell
brew install terraform awscli yq
```
2. Create AWS account
   * https://amazon.com/aws
3. If the file `~/.aws/credentials` doesn't exist, create it and add you Terraform profile to the file. For example:
```text
   [terraform]
   aws_access_key_id = Your access key
   aws_secret_access_key = Your secret access key 
```
4. Check AWS account
```shell
aws sts get-caller-identity
```
5. Create S3 bucket to store Terraform state
```shell
aws s3api create-bucket --bucket world-terraform --region us-east-1
```
6. Create config file `config.tf` that will contain information how to store state in a given bucket. See [example](./src/free-tier/backend/example.config.tf).

8. Create SSH key pair to connect to EC2 instance:
```shell
   cd ./src/free-tier/provision/access

   # it creates "free-tier-ec2-key" private key and "free-tier-ec2-key.pub" public key
   ssh-keygen -f free-tier-ec2-key
``` 
   
### Build infrastructure

```shell
cd ./src/free-tier
terraform init -backend-config="./backend/config.tf"
```

```shell
cd ./src/free-tier
terraform plan
```

```shell
cd ./src/free-tier
terraform apply
```

# Post install

```shell
ssh-add src/free-tier/provision/access/free-tier-ec2-key
ip=$(aws ec2 describe-instances | 
      yq 'select(.Reservations[].Instances[].State.Code == 16) | .Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddresses[].Association.PublicIp')
echo $ip
```

   * Edit /etc/hosts add "aws" host name
```shell
sudo bash -c "echo $ip aws >> /etc/hosts"
```

```shell
ssh-keygen -R aws  
ssh-keyscan -H aws >> ~/.ssh/known_hosts
ssh-keygen -R $ip
ssh-keyscan -H $ip >> ~/.ssh/known_hosts
```

```shell
ssh ec2-user@$ip "sudo amazon-linux-extras install epel postgresql14 -y"
```

   * FIXME
```shell
ssh ec2-user@$ip "sudo yum update && sudo yum install -y openvpn postgresql"
```

```shell
ssh ec2-user@$ip "sudo yum update && sudo yum upgrade && sudo yum install -y netcat openvpn"
```

```shell
ssh ec2-user@$ip "sudo yum update && sudo yum install -y docker python3-pip htop && sudo usermod -a -G docker ec2-user && sudo pip3 install docker-compose"
```

```shell
ssh ec2-user@$ip "sudo systemctl enable docker.service && sudo systemctl start docker.service && systemctl status docker.service"
```

   * Edit src/docker/env-duckdns.sh
```text
SUBDOMAINS=your-subdomain
DUCKDNS_TOKEN=your-token
TOKEN=$DUCKDNS_TOKEN
``` 

   * Edit src/docker/docker-compose.yaml, set email and Duckdns subdomain FIXME
   * Edit src/docker/conf/users.txt FIXME

```shell
ssh ec2-user@$ip "mkdir -p docker/conf"
 ```

```shell
scp src/docker/docker-compose.yaml src/docker/env-duckdns.sh ec2-user@$ip:./docker/
scp src/docker/conf/dynamic_conf.yml ec2-user@$ip:./docker/conf/dynamic_conf.yml
scp src/docker/conf/users.txt ec2-user@$ip:./docker/conf/users.txt
```

```shell
ssh ec2-user@$ip "cd docker && docker-compose up -d"
```

# Duckns
   * https://www.duckdns.org/

   * ./src/docker/env-duckdns.sh
```text
TZ=America/Sao_Paulo
SUBDOMAINS=sub-domain-1,sub-domain-2,sub-domain-3,sub-domain-4,sub-domain-5
DUCKDNS_TOKEN=your-token
TOKEN=your-token
```

   * Duckdns logs
```shell
ssh ec2-user@$ip "cd docker && docker-compose logs duckdns"
```

# Traefik
   * Traefik logs
```shell
ssh ec2-user@$ip "cd docker && docker-compose logs traefik"
```

# AWS RDS
```shell
aws rds describe-db-instances | yq
```

   * Get Postgres endpoint
```shell
address=$(aws rds describe-db-instances | yq '.DBInstances[] | select(.DBName=="labdb") | .Endpoint.Address')
port=$(aws rds describe-db-instances | yq '.DBInstances[] | select(.DBName=="labdb") | .Endpoint.Port')
echo $address:$port
```

   * Get EC2 ip, add SSH private key
```shell
ssh-add src/free-tier/provision/access/free-tier-ec2-key
ip=$(aws ec2 describe-instances | 
      yq 'select(.Reservations[].Instances[].State.Code == 16) | .Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddresses[].Association.PublicIp')
echo $ip
```

   * Check Postgres routing from EC2
```shell
ssh ec2-user@$ip "nc -v $address $port"
```

   * Postgres cli
```shell
ssh ec2-user@$ip psql --host labdb.ca7llygc5a1p.us-east-1.rds.amazonaws.com  --port 3306 --username postgres
```

# Destroy infrastructure
```shell
cd ./src/free-tier
terraform destroy
```
