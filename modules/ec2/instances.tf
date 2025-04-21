resource "aws_instance" "public_instance" {
    ami = "ami-084568db4383264d4"
    instance_type = var.public_instance_type
    key_name = var.key_pair_name
    subnet_id = var.public_subnet

    associate_public_ip_address = true

    tags = {
        Name = "public_instance"
    }
}

resource "aws_instance" "private_instance" {
    ami = "ami-084568db4383264d4"
    instance_type = var.private_instance_type
    key_name = var.key_pair_name
    subnet_id = var.private_subnet

    tags = {
        Name = "private_instance"
    }
}