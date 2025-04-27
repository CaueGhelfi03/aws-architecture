variable "key_pair_name" {
  type = string
}

variable "private_instance_type" {
    type = string
    default = "t2.micro"
    description = "Private instance"
}

variable "public_instance_type" {
    type = string
    default = "t2.micro"
    description = "Public instance" 
}

variable "public_subnet" {
  type = string
}

variable "public_subnet_id" {
  type    = string
  description = " Public subnet CIDRs "
}

variable "private_subnet_id" {
  type    = string
  description = "Private subnet CIDRs"
}

variable "private_subnet" {
  type = string
}

variable "basic_security_group_id" {
  description = "Basic security group ID"
  type        = string
}