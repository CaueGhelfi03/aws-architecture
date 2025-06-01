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

resource "aws_route" "private_route_no_nat" {
  route_table_id = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.id
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

resource "aws_security_group" "public_security" {
  name = "public_security"
  description = "Allow SSH access"
  vpc_id = var.vpc_id

  ingress { 
    description = "SSH from anywhere"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP address
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public_security"
  }
}

resource "aws_security_group" "private_instance_sg" {
  name        = "private_instance_sg"
  description = "Allow SSH only from public instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from public instance only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.public_security.id]
  }

  #MySQL
  ingress {
    description = "MySQL access from public instance"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.public_security.id]
  }

  ingress {
    description = "API access from public instance"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.public_security.id]
  }


  # Regras de SAÍDA (Outbound) - Liberando internet
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Libera HTTP para internet"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Libera HTTPS para internet"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Libera DNS (UDP) para internet"
  }

  tags = {
    Name = "private_instance_sg"
  }
}

output "public_security_group_id" {
  value = aws_security_group.public_security.id
}

output "private_instance_sg_id" {
  value = aws_security_group.private_instance_sg.id
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