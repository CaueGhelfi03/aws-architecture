resource "aws_instance" "public_instance" {
    ami = "ami-084568db4383264d4"
    instance_type = var.public_instance_type
    key_name = var.key_pair_name
    subnet_id = var.public_subnet_id
    associate_public_ip_address = true

    vpc_security_group_ids = [var.basic_security_group_id]

    user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt update -y
              sudo apt install nginx -y
              # Node.js e React
              curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
              sudo apt install -y nodejs
              sudo npm install -g create-react-app
              EOF
    tags = {
        Name = "public_instance"
    }
}

resource "aws_instance" "private_instance" {
    ami = "ami-084568db4383264d4"
    instance_type = var.private_instance_type
    key_name = var.key_pair_name
    subnet_id = var.private_subnet_id

    user_data = <<-EOF
            #!/bin/bash
            # Atualiza pacotes
            sudo apt update -y

            # Instala o JDK 11
            sudo apt install -y openjdk-11-jdk

            # Habilita o MySQL no boot e inicia agora
            sudo systemctl enable mysql
            sudo systemctl start mysql

            # (Opcional) Configura senha do root
            sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'senha123'; FLUSH PRIVILEGES;"
            EOF

    tags = {
        Name = "private_instance"
    }
}