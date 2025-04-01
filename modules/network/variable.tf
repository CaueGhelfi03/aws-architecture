variable "key_pair_name" {
  type    = string
  default = "id_rsa"
  description = "Key par ssh name"
}

variable "public_subnet_id" {
  type    = string
  description = " Public subnet CIDRs "
}

variable "private_subnet_id" {
  type    = string
  description = "Private subnet CIDRs"
}

variable "vpc_id" {
  type    = string
  description = "VPC ID"
}