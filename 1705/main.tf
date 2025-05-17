
resource "aws_vpc" "myvpc" {
  cidr_block       = "20.0.0.0/20"
  instance_tenancy = "default"

  tags = {
    Name = "tf1705"
  }
}

resource "aws_subnet" "mysubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "20.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf1705"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "tf1705"
  }
}

resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "tf1705"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.publicrt.id
}

resource "aws_security_group" "apache_sg" {
  name        = "apache-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.myvpc.id


  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf1705"
  }
}

resource "aws_instance" "myec2" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.mysubnet.id
  vpc_security_group_ids = [aws_security_group.apache_sg.id]
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              curl -O https://raw.githubusercontent.com/AbdelrhmanKamall/Scripts/main/apache.sh
              chmod +x apache.sh
              ./apache.sh
              EOF

  tags = {
    Name = "tf1705"
  }
}

