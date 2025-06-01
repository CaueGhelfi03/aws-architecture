terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

variable "key_pair_name" {
  type    = string
  default = "id_rsa"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24"]
}

variable "private_api_instance_type" {
    type = string
    default = "t2.small"
    description = "Private api instance"
}

variable "private_db_instance_type" {
    type = string
    default = "t2.micro"
    description = "Private db instance"
}

variable "public_instance_type" {
    type = string
    default = "t2.micro"
    description = "Public instance" 
}

variable "instance_public_eip"{
  description = "Elastic IP for public instance"
  type        = string 
}

resource "aws_vpc" "vpc_main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_main.id
  tags = {
    Name = "main-igw"
  }
}

# Criando a sub-rede pública
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = var.public_subnet_cidrs[0]
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

# Criando a sub-rede privada
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = var.private_subnet_cidrs[0]
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_eip" "nat_iep" {
  vpc = true
  tags = {
    Name = "nat_iep"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id     = aws_eip.nat_iep.id
  subnet_id         = aws_subnet.public_subnet.id
  connectivity_type = "public"

  tags = {
    Name = "nat_gateway"
  }  
}

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.vpc_main.id

  subnet_ids = [aws_subnet.private_subnet.id]
  tags = {
    Name = "private_nacl"
  }
}

# Saída HTTP/HTTPS
resource "aws_network_acl_rule" "private_outbound_http_https" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 90
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 443
}

# Saída DNS UDP
resource "aws_network_acl_rule" "private_outbound_dns" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 95
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 53
  to_port        = 53
}

# Saída tráfego efêmero para NAT
resource "aws_network_acl_rule" "private_outbound_nat" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Saída tráfego interno (VPC)
resource "aws_network_acl_rule" "private_outbound_internal" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 110
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.vpc_main.cidr_block
  from_port      = 0
  to_port        = 0
}

# Entrada retorno NAT efêmero TCP
resource "aws_network_acl_rule" "private_inbound_return_nat" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_vpc.vpc_main.cidr_block
  from_port      = 1024
  to_port        = 65535
}

# Entrada retorno DNS UDP
resource "aws_network_acl_rule" "private_inbound_dns" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 105
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = aws_vpc.vpc_main.cidr_block
  from_port      = 53
  to_port        = 53
}

# Entrada tráfego interno (VPC)
resource "aws_network_acl_rule" "private_inbound_internal" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.vpc_main.cidr_block
  from_port      = 0
  to_port        = 0
}

module "network" {
  source               = "./modules/network"
  key_pair_name        = var.key_pair_name
  vpc_id               = aws_vpc.vpc_main.id
  public_subnet_id     = aws_subnet.public_subnet.id
  private_subnet_id    = aws_subnet.private_subnet.id
}

module "instance" {
  source               = "./modules/ec2"
  key_pair_name        = var.key_pair_name
  public_subnet        = module.network.public_subnet_id
  private_subnet       = module.network.private_subnet_id
  private_subnet_id = module.network.private_subnet_id
  public_subnet_id = module.network.public_subnet_id
  public_instance_type = var.public_instance_type
  private_api_instance_type = var.private_api_instance_type
  private_db_instance_type = var.private_db_instance_type 
  basic_security_group_id = module.network.public_security_group_id
  private_instance_sg = module.network.private_instance_sg_id
  instance_public_eip = var.instance_public_eip
}

output "vpc_id" {
  value = aws_vpc.vpc_main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnet.id
}
