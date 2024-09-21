
# VPC CIDR BLOCK
variable "aws_vpc" {
  default = "10.0.0.0/16"
}

# Public Subnet1
variable "aws_pub1" {
  default = "10.0.1.0/24"
}

# Public Subnet2
variable "aws_pub2" {
  default = "10.0.2.0/24"
}

# Private Subnet1
variable "aws_priv1" {
  default = "10.0.3.0/24"
}

# Private Subnet2
variable "aws_priv2" {
  default = "10.0.4.0/24"
}

# All IP CIDR
variable "all_ip" {
  default = "0.0.0.0/0"
}
# ssh port
variable "SSH" {
  default = 22
}

# allow all traffic from every IP addres
variable "allow_all_IP" {
  default = ["0.0.0.0/0"]
}

# http port
variable "http-port" {
  default = 8080
}

variable "egress_from_and_to" {
  default = 0
}

variable "egress_protocol" {
  default = "-1"
}

# EC2 INSTANCE
variable "redhat" {
  default = "ami-0574a94188d1b84a1"
}

#instance type
variable "instance_type" {
  default = "t2.medium"
}