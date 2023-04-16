#create the provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "myvpc1" {
  cidr_block = "10.0.0.0/16"
}

#create 2 public subnets
resource "aws_subnet" "web_subnet1" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Web_subnet"
  }
}

resource "aws_subnet" "web_subnet2" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "web_subnet2"
  }
}

#create a internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc1.id

  tags = {
    Name = "mainigw"
  }
}  


# create a route table for the public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.myvpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-routetable-forsubnets"
  }
}

#create route table to associate public subnet 1 and subnet 2
resource "aws_route_table_association" "web_subnet1" {
  subnet_id = aws_subnet.web_subnet1.id 
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "web_subnet2" {
  subnet_id = aws_subnet.web_subnet2.id 
  route_table_id = aws_route_table.public_rt.id
}

#Create 2 private subnet
resource "aws_subnet" "rds_privatesubnet1" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "rds_privatesubnet1"
  }
}

resource "aws_subnet" "rds_privatesubnet2" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "rds_privatesubnet2"
  }
}

# Create a route table for the private subnets
resource "aws_route_table" "private_rt" {
  vpc_id =  aws_vpc.myvpc1.id

  tags = {
    Name = "private-routetable-subnets"
  }
}


#create route table to associate private subnet 1 and subnet 2
resource "aws_route_table_association" "web_privatesubnet1" {
  subnet_id = aws_subnet.web_privatesubnet1.id 
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "web_privatesubnet2" {
  subnet_id = aws_subnet.web_privatesubnet2.id 
  route_table_id = aws_route_table.private_rt.id
}


#ec2 instance using public subnets
resource "aws_instance" "publicsubnetinstance1" {
  ami           = "ami-069aabeee6f53e7bf"
  instance_type = "t2.micro"
  subnet_id     = "web_subnet1"
  user_data = "${file("user-data-apache.sh")}"


  tags = {
    Name = "publicsubnetinstance1 Instance"
  }
}

resource "aws_instance" "publicsubnetinstance2" {
  ami           = "ami-069aabeee6f53e7bf"
  instance_type = "t2.micro"
  subnet_id     = "web_subnet2"
    user_data = "${file("user-data-nginx.sh")}" 

  tags = {
    Name = "publicsubnetinstance2 Instance"
  }
}


#create RDS MySQL Instance (micro) in the private RDS subnets

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = [aws_subnet.rds_privatesubnet1.id, aws_subnet.rds_privatesubnet2.id]
}



resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "mysqlinstance"
  password             = "mymymysql"
  parameter_group_name = "default.mysqll"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.dbsubnetgroup.name

}

#security group for RDS
resource "aws_security_group" "rdssecurity" {
  name        = "rdssecurity"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.myvpc1.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.myvpc1.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.myvpc1.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_rds"
  }
}

#security group for web server 
resource "aws_security_group" "websecurity" {
  name        = "websecurity"
  description = "Allow inbound traffic for web"
  vpc_id      = aws_vpc.myvpc1.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.myvpc1.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.myvpc1.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


