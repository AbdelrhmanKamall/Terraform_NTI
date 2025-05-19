
resource "aws_vpc" "mainvpc" {
  cidr_block       = var.cidr_block[0]
  instance_tenancy = "default"

  tags = {
    Name = "tf1805"
  }
}

# public subnet with its routing table
resource "aws_subnet" "mypublicsubnet" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = var.cidr_block[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf1805"
  }
}

resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.mainvpc.id

  route {
    cidr_block = var.allowed_cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "tf1805"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.mypublicsubnet.id
  route_table_id = aws_route_table.publicrt.id
}



# private subnet with its routing table
resource "aws_subnet" "myprivatesubnet" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = var.cidr_block[2]

  tags = {
    Name = "tf1805"
  }
}

resource "aws_route_table" "privatert" {
  vpc_id = aws_vpc.mainvpc.id

  route {
    cidr_block = var.allowed_cidr_block
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "tf1805"
  }
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.myprivatesubnet.id
  route_table_id = aws_route_table.privatert.id
}




# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mainvpc.id

  tags = {
    Name = "tf1805"
  }
}




# nat gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"  
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.mypublicsubnet.id

  tags = {
    Name = "tf1805"
  }
}




# public security group
resource "aws_security_group" "public_instance_sg" {
  name        = "allow_SSH"
  description = "Allow SSH inbound traffic"
  vpc_id = aws_vpc.mainvpc.id

  ingress {
    description = "Allow SSH"
    from_port   = var.ports[1]
    to_port     = var.ports[1]
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allowed_cidr_block]
  }

  tags = {
    Name = "tf1805"
  }
}





# private security group
resource "aws_security_group" "privateapache_sg" {
  name        = "apache-sg"
  description = "Allow SSH from public ec2"
  vpc_id      = aws_vpc.mainvpc.id


  ingress {
    description = "Allow SSH from Public EC2 only"
    from_port   = var.ports[1]
    to_port     = var.ports[1]
    protocol    = "tcp"
    security_groups = [aws_security_group.public_instance_sg.id]
  }
  
  ingress {
    description = "Allow Http from Public EC2 only"
    from_port   = var.ports[2]
    to_port     = var.ports[2]
    protocol    = "tcp"
    security_groups = [aws_security_group.public_instance_sg.id]
  }

  ingress {
    description = "Allow ping from Public EC2 only"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    security_groups = [aws_security_group.public_instance_sg.id]
  }
  
  egress {
    description = "Allow all outbound traffic"
    from_port   = var.ports[0]
    to_port     = var.ports[0]
    protocol    = "-1"
    cidr_blocks = [var.allowed_cidr_block]
  }

  tags = {
    Name = "tf1805"
  }
}




# Bastion host
resource "aws_instance" "public_inst" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.mypublicsubnet.id
  vpc_security_group_ids = [ aws_security_group.public_instance_sg.id ]
  associate_public_ip_address = true
  key_name                    = "tf_user"

  tags = {
    Name = "tf1805"
  }
}





# Apache server
resource "aws_instance" "private_inst" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.myprivatesubnet.id
  vpc_security_group_ids      = [aws_security_group.privateapache_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              curl -O https://raw.githubusercontent.com/AbdelrhmanKamall/Scripts/main/apache.sh
              chmod +x apache.sh
              ./apache.sh
              EOF

  tags = {
    Name = "tf1805"
  }
}

