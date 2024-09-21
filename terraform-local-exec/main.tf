# Create Custom VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.aws_vpc

  tags = {
    Name = "lington-vpc"
  }
}

# Create a Public Subnet01 in AZ1
resource "aws_subnet" "lington-pub1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.aws_pub1
  availability_zone = "eu-west-3a"

  tags = {
    Name = "lington-pub1"
  }
}

#  Create a Public Subnet02 in AZ2
resource "aws_subnet" "lington-pub2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.aws_pub2
  availability_zone = "eu-west-3b"

  tags = {
    Name = "lington-pub2"
  }
}

#  Create a Private Subnet01 in AZ1
resource "aws_subnet" "lington-priv1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.aws_priv1
  availability_zone = "eu-west-3a"

  tags = {
    Name = "lington-priv1"
  }
}

#  Create a Private Subnet02 in AZ2
resource "aws_subnet" "lington-priv2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.aws_priv2
  availability_zone = "eu-west-3b"

  tags = {
    Name = "lington-priv2"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "lington-igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "lington-igw"
  }
}

# Create Nat Gateway
resource "aws_nat_gateway" "lington-nat" {
  allocation_id = aws_eip.lington_EIP.id
  subnet_id     = aws_subnet.lington-pub1.id

  tags = {
    Name = "lington-nat"
  }
}

# Creating Elastic IP for NAT Gateway
resource "aws_eip" "lington_EIP" {
  vpc = true
}

# Create Public Route Table, attach to VPC, allow access from every ip, attach to IGW
resource "aws_route_table" "lington_RT_Pub_SN" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.all_ip
    gateway_id = aws_internet_gateway.lington-igw.id
  }

  tags = {
    Name = "lington_RT_Pub_SN"
  }
}

# Create Private Route Table, attach to VPC, allow access from every ip, attach to NGW
resource "aws_route_table" "lington_RT_Pri_SN" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = var.all_ip
    nat_gateway_id = aws_nat_gateway.lington-nat.id
  }

  tags = {
    Name = "lington_RT_Pri_SN"
  }
}

# Creating Route Table Associations 
resource "aws_route_table_association" "lington_Public_RT1" {
  subnet_id      = aws_subnet.lington-pub1.id
  route_table_id = aws_route_table.lington_RT_Pub_SN.id
}
resource "aws_route_table_association" "lington_Public_RT2" {
  subnet_id      = aws_subnet.lington-pub2.id
  route_table_id = aws_route_table.lington_RT_Pub_SN.id
}
resource "aws_route_table_association" "lington_Private_RT1" {
  subnet_id      = aws_subnet.lington-priv1.id
  route_table_id = aws_route_table.lington_RT_Pri_SN.id
}
resource "aws_route_table_association" "lington_Private_RT2" {
  subnet_id      = aws_subnet.lington-priv2.id
  route_table_id = aws_route_table.lington_RT_Pri_SN.id
}

# Create keypair with Terraform
resource "tls_private_key" "prv-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "Key_priv" {
  filename        = "keypair.pem"
  content         = tls_private_key.prv-key.private_key_pem
  file_permission = "600"
}

resource "aws_key_pair" "Key_pub" {
  key_name   = "keypair"
  public_key = tls_private_key.prv-key.public_key_openssh
}

# Create a Security group (FRONT END)
resource "aws_security_group" "Front-end-SG" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = var.SSH
    to_port     = var.SSH
    protocol    = "tcp"
    cidr_blocks = var.allow_all_IP

  }

  ingress {
    description = "TLS from VPC"
    from_port   = var.http-port
    to_port     = var.http-port
    protocol    = "tcp"
    cidr_blocks = var.allow_all_IP

  }

  egress {
    from_port   = var.egress_from_and_to
    to_port     = var.egress_from_and_to
    protocol    = var.egress_protocol
    cidr_blocks = var.allow_all_IP

  }

  tags = {
    Name = "lington-Front-end-SG"
  }
}

# Create a Security group (BACK END)
resource "aws_security_group" "Back-end-SG" {
  name = "allow_tlss" # note both security group cant have the same name

  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = var.SSH
    to_port     = var.SSH
    protocol    = "tcp"
    cidr_blocks = var.allow_all_IP

  }


  egress {
    from_port   = var.egress_from_and_to
    to_port     = var.egress_from_and_to
    protocol    = var.egress_protocol
    cidr_blocks = var.allow_all_IP

  }

  tags = {
    Name = "Back-end-SG"
  }
}


# it is just for executing some bash/shell commad on our local machine
# notes 1: you need to automate your prv keypair ready before you apply null resource OR \
# you apply first you infrasture but you apply the null resources 
# you can only apply ones to copy your file
resource "aws_instance" "jenkins-controller" {
  ami                         = var.redhat
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name               = aws_key_pair.Key_pub.key_name
  subnet_id              = aws_subnet.lington-pub2.id
  vpc_security_group_ids = [aws_security_group.Front-end-SG.id]



  tags = {
    Name = "jenkins-controller"
  }

  connection {

    type        = "ssh"
    host        = aws_instance.jenkins-controller.public_ip
    user        = "ec2-user"
    private_key = file("~/Downloads/devops/terraform-test/terraform-local-exec/keypair.pem")
    timeout     = "4m"

  }

  provisioner "local-exec" {
    command = "echo 'hello-word.txt' > wold.tf"
  }

}

