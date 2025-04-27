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

variable "private_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "public_instance_type" {
  type    = string
  default = "t2.micro"
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair_name
  public_key = file("${path.root}/id_rsa.pem.pub")
}

resource "aws_vpc" "vpc_main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main_vpc"
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
  private_instance_type = var.private_instance_type
  basic_security_group_id = module.network.basic_security_group_id
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
