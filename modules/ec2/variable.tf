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

variable "private_subnet" {
  type = string
}