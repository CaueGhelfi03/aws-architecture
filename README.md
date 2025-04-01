# AWS Network Architecture with Terraform

This repository contains the Terraform configuration for setting up a **VPC-based network architecture** on AWS.

## 📌 Architecture Overview

This infrastructure includes:
- **VPC (10.0.0.0/24)**
- **Public Subnet (10.0.0.0/25)**  
  - Connected to an **Internet Gateway**  
  - Uses a **public route table**  
- **Private Subnet (10.0.0.128/25)**  
  - Routes external traffic through a **NAT Gateway**  
  - Uses a **private route table**  

## ⚙️ Deployment

To deploy this infrastructure, run:
```sh
terraform init
terraform apply -auto-approve
```

![image](https://github.com/user-attachments/assets/d3dec029-5937-4f3f-8df9-a0c51f2ffa8c)
