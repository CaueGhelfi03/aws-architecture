resource "aws_instance" "public_instance" {
    ami = "ami-084568db4383264d4"
    instance_type = var.public_instance_type
    key_name = var.key_pair_name
    subnet_id = var.public_subnet_id

    vpc_security_group_ids = [var.basic_security_group_id]

    user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y nginx
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
    sudo mkdir -p /etc/apt/keyrings

    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable nginx
    sudo systemctl start nginx
    sudo systemctl enable docker

        cat <<NGINX_CONF | sudo tee /etc/nginx/sites-available/default > /dev/null
    upstream backend{
      server IP_DA_INSTANCIA_BACKEND:8080;
      server IP_DA_INSTANCIA_BACKEND:8080;
    }
    
    server {
        listen 80;
        server_name adoteme.com;


        root /var/www/html/dist;
        index index.html;

        location /api {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
    NGINX_CONF

    sudo systemctl restart nginx
    EOF
    tags = {
        Name = "public_instance"
    }

}
resource "aws_eip_association" "instance_public_eip" {
  instance_id = aws_instance.public_instance.id
  allocation_id = "eipalloc-00eb8358993ef4128"  
}

resource "aws_instance" "private_instance_api_1" {
    ami = "ami-084568db4383264d4"
    instance_type = var.private_api_instance_type
    key_name = var.key_pair_name
    subnet_id = var.private_subnet_id
    

    vpc_security_group_ids = [var.private_instance_sg]

        user_data = <<-EOF
        #!/bin/bash
        exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
        set -e

        # Aguarda conexão com a internet
        until nc -z 8.8.8.8 53; do
          echo "Aguardando conectividade com a internet..."
          sleep 5
        done

        sudo apt update -y
        sudo apt install -y openjdk-11-jdk mysql-server openssh-client apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu `lsb_release -cs` stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update -y
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        java -version >> /var/log/java-install.log 2>&1
        EOF

    tags = {
        Name = "private_instance_api_1"
    }
}

resource "aws_instance" "private_instance_api_2" {
    ami = "ami-084568db4383264d4"
    instance_type = var.private_api_instance_type
    key_name = var.key_pair_name
    subnet_id = var.private_subnet_id
    

    vpc_security_group_ids = [var.private_instance_sg]

        user_data = <<-EOF
        #!/bin/bash
        exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
        set -e

        # Aguarda conexão com a internet
        until nc -z 8.8.8.8 53; do
          echo "Aguardando conectividade com a internet..."
          sleep 5
        done

        sudo apt update -y
        sudo apt install -y openjdk-11-jdk mysql-server openssh-client apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu `lsb_release -cs` stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update -y
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        java -version >> /var/log/java-install.log 2>&1
        EOF

    tags = {
        Name = "private_instance_api_2"
    }
}

resource "aws_instance" "private_instance_db" {
    ami = "ami-084568db4383264d4"
    instance_type = var.private_db_instance_type
    key_name = var.key_pair_name
    subnet_id = var.private_subnet_id


    vpc_security_group_ids = [var.private_instance_sg]

    user_data = <<-EOF
                    #!/bin/bash -xe

                    cloud-init status --wait

                    echo "Atualizando pacotes..."
                    sleep 10  # Pequeno delay para garantir acesso à rede
                    apt-get update -y
                    apt-get install -y mysql-server || apt-get install -y mysql-server-8.0

                    echo "Iniciando serviço do MySQL..."
                    systemctl enable --now mysql

                    echo "Configurando senha do usuário root..."
                    # Método mais robusto para configurar a senha root
                    mysql --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'senha123'; FLUSH PRIVILEGES;" || \
                    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'senha123'; FLUSH PRIVILEGES;"

                    echo "Permitindo conexões externas..."
                    [ -f /etc/mysql/mysql.conf.d/mysqld.cnf ] && sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
                    [ -f /etc/mysql/my.cnf ] && sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf
                    systemctl restart mysql

                    echo "Criando banco e usuário..."
                    mysql -uroot -psenha123 -e "CREATE DATABASE IF NOT EXISTS adoteme;"
                    mysql -uroot -psenha123 -e "CREATE USER IF NOT EXISTS 'usuario'@'%' IDENTIFIED BY 'senha';"
                    mysql -uroot -psenha123 -e "GRANT ALL PRIVILEGES ON adoteme.* TO 'usuario'@'%';"
                    mysql -uroot -psenha123 -e "FLUSH PRIVILEGES;"

                    echo "Liberando porta 3306 no firewall..."
                    ufw allow 3306/tcp || true

                    echo "User-data finalizado com sucesso."
              EOF

    tags = {
        Name = "private_instance_db"
    }
}

resource "null_resource" "send_files" {
  depends_on = [aws_eip_association.instance_public_eip]

  provisioner "file" {
    source      = "id_rsa.pem"
    destination = "/home/ubuntu/id_rsa.pem"
    connection {
      type        = "ssh"
      host        = aws_eip_association.instance_public_eip.public_ip
      user        = "ubuntu"
      private_key = file("id_rsa.pem")
    }
  }

   provisioner "file" {
    source      = "dist"
    destination = "/home/ubuntu/dist"
    connection {
      type        = "ssh"
      host        = aws_eip_association.instance_public_eip.public_ip
      user        = "ubuntu"
      private_key = file("id_rsa.pem")
    }
  }
}

