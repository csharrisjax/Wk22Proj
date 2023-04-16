#create a VPC
variable "vpc_cidr_block" {
  type = string
  default = "10.0.0.0/16"
}

#create 2 subnets

variable "subnet_cidr_blocks" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "subnet_names" {
  type = list(string)
  default = ["Web_subnet", "web_subnet2"]
}

# create a route table for the public subnets
variable "vpc_id" {
  type = string
}

variable "igw_name" {
  type = string
}

#create route table to associate public subnet 1 and subnet 2
variable "web_subnet1_id" {
  type = string
}

variable "web_subnet2_id" {
  type = string
}

variable "public_route_table_id" {
  type = string
}


#Create 2 private subnets
variable "rds_subnet_cidr_block_1" {
  type    = string
  default = "10.0.3.0/24"
}

variable "rds_subnet_cidr_block_2" {
  type    = string
  default = "10.0.4.0/24"
}

variable "rds_subnet_name_1" {
  type    = string
  default = "rds_privatesubnet1"
}

variable "rds_subnet_name_2" {
  type    = string
  default = "rds_privatesubnet2"
}


# Create a route table for the private subnets
resource "aws_route_table" "private_rt" {
  vpc_id =  aws_vpc.myvpc1.id

  tags = {
    Name = "private-routetable-subnets"
  }
}


#create route table to associate private subnet 1 and subnet 2
variable "web_privatesubnet1_id" {
  type = string
}

variable "web_privatesubnet2_id" {
  type = string
}

variable "private_rt_id" {
  type = string
}



#ec2 instance using public subnets
variable "web_subnet1_id" {
  description = "ID of the web subnet 1"
}

variable "web_subnet2_id" {
  description = "ID of the web subnet 2"
}

resource "aws_instance" "publicsubnetinstance1" {
  ami           = "ami-069aabeee6f53e7bf"
  instance_type = "t2.micro"
  subnet_id     = var.web_subnet1_id
  user_data     = "${file("user-data-apache.sh")}"

  tags = {
    Name = "publicsubnetinstance1 Instance"
  }
}

resource "aws_instance" "publicsubnetinstance2" {
  ami           = "ami-069aabeee6f53e7bf"
  instance_type = "t2.micro"
  subnet_id     = var.web_subnet2_id
  user_data     = "${file("user-data-nginx.sh")}"

  tags = {
    Name = "publicsubnetinstance2 Instance"
  }
}



#create RDS MySQL Instance (micro) in the private RDS subnets

variable "dbsubnetgroup_name" {
  description = "The name of the RDS DB subnet group"
  type        = string
  default     = "dbsubnetgroup"
}

variable "dbsubnetgroup_subnets" {
  description = "The subnets associated with the RDS DB subnet group"
  type        = list(string)
  default     = [aws_subnet.rds_privatesubnet1.id, aws_subnet.rds_privatesubnet2.id]
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = var.dbsubnetgroup_name
  subnet_ids = var.dbsubnetgroup_subnets
}




variable "allocated_storage" {
  default = 10
}

variable "db_name" {
  default = "mydb"
}

variable "engine" {
  default = "mysql"
}

variable "engine_version" {
  default = "5.7"
}

variable "instance_class" {
  default = "db.t3.micro"
}

variable "username" {
  default = "mysqlinstance"
}

variable "password" {
  default = "mymymysql"
}

variable "parameter_group_name" {
  default = "default.mysqll"
}

variable "skip_final_snapshot" {
  default = true
}

variable "db_subnet_group_name" {
  default = aws_db_subnet_group.dbsubnetgroup.name
}

}


#security group for RDS
variable "rds_sg_name" {
  description = "Name of the security group for RDS"
  type        = string
  default     = "rdssecurity"
}

variable "rds_sg_description" {
  description = "Description of the security group for RDS"
  type        = string
  default     = "Allow inbound traffic"
}

variable "rds_sg_tls_port" {
  description = "TLS port to be allowed from VPC"
  type        = number
  default     = 443
}

variable "rds_sg_cidr_block" {
  description = "CIDR block to be allowed for inbound traffic"
  type        = list(string)
  default     = [aws_vpc.myvpc1.cidr_block]
}

variable "rds_sg_ipv6_cidr_block" {
  description = "IPv6 CIDR block to be allowed for inbound traffic"
  type        = list(string)
  default     = [aws_vpc.myvpc1.ipv6_cidr_block]
}

variable "rds_sg_egress_cidr_block" {
  description = "CIDR block to be allowed for egress traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "rds_sg_egress_ipv6_cidr_block" {
  description = "IPv6 CIDR block to be allowed for egress traffic"
  type        = list(string)
  default     = ["::/0"]
}

variable "rds_sg_tags" {
  description = "Tags for the security group"
  type        = map(string)
  default     = {
    Name = "allow_rds"
  }
}


#security group for web server 
variable "websecurity_name" {
  type        = string
  description = "The name of the web security group"
  default     = "websecurity"
}

variable "websecurity_description" {
  type        = string
  description = "The description of the web security group"
  default     = "Allow inbound traffic for web"
}

variable "websecurity_from_port" {
  type        = number
  description = "The starting port number to allow incoming traffic from"
  default     = 443
}

variable "websecurity_to_port" {
  type        = number
  description = "The ending port number to allow incoming traffic to"
  default     = 443
}

variable "websecurity_protocol" {
  type        = string
  description = "The protocol to use for incoming traffic"
  default     = "tcp"
}

variable "websecurity_cidr_blocks" {
  type        = list(string)
  description = "The CIDR blocks to allow incoming traffic from"
  default     = [aws_vpc.myvpc1.cidr_block]
}

variable "websecurity_ipv6_cidr_blocks" {
  type        = list(string)
  description = "The IPv6 CIDR blocks to allow incoming traffic from"
  default     = [aws_vpc.myvpc1.ipv6_cidr_block]
}

variable "websecurity_egress_from_port" {
  type        = number
  description = "The starting port number to allow outgoing traffic from"
  default     = 0
}

variable "websecurity_egress_to_port" {
  type        = number
  description = "The ending port number to allow outgoing traffic to"
  default     = 0
}

variable "websecurity_egress_protocol" {
  type        = string
  description = "The protocol to use for outgoing traffic"
  default     = "-1"
}

variable "websecurity_egress_cidr_blocks" {
  type        = list(string)
  description = "The CIDR blocks to allow outgoing traffic to"
  default     = ["0.0.0.0/0"]
}

variable "websecurity_egress_ipv6_cidr_blocks" {
  type        = list(string)
  description = "The IPv6 CIDR blocks to allow outgoing traffic to"
  default     = ["::/0"]
}


  tags = {
    Name = "allow_web"
  }
}


