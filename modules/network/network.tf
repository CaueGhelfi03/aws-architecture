resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = var.vpc_id
  tags = {
    Name = "internet_gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id
  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id
  tags = {
    Name = "private_rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id = var.public_subnet_id  
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id = var.private_subnet_id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
}

resource "aws_eip" "nat_iep" {
  vpc = true
  tags = {
    Name = "nat_iep"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_iep.id
  subnet_id =  var.public_subnet_id
  connectivity_type = "public"

  tags = {
    Name = "nat_gateway"
  }  
}

resource "aws_route" "private_route" {
  route_table_id = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.id 
}

resource "aws_security_group" "basic_security" {
  name = "basic_security"
  description = "Allow SSH access"
  vpc_id = var.vpc_id

  ingress { 
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpc_id" {
  value = var.vpc_id
}

output "public_subnet_id" {
  value = var.public_subnet_id
}

output "private_subnet_id" {
  value = var.private_subnet_id
}