provider "aws" {
  region = "eu-central-1"
}


# EC2 Instance (Sunucu)
resource "aws_instance" "demo-server" {
  ami             = "ami-0a628e1e89aaedf80"  # AMI ID, doğru bölgeye ait olmalı
  instance_type   = "t2.micro"  
  key_name        = "mcan97"  # AWS'de önceden oluşturulmuş bir keypair olmalı
  subnet_id       = aws_subnet.mcan97-public-subnet-01.id  # Alt ağ ID'si
  for_each = toset(["jenkins-master", "build-slave", "ansible"])
  vpc_security_group_ids = [aws_security_group.demo-sg.id]  # Güvenlik grubunun VPC ID'sini kullanıyoruz
  
  tags = {
    Name = "${each.key}"
  }
}

# Güvenlik Grubu
resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"
  vpc_id      = aws_vpc.mcan97-vpc.id  # VPC ile ilişkilendiriliyor
  
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
   ingress {
    description = "Jenkins port"
    from_port   = 5050
    to_port     = 5050
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-prot"
  }
}

# VPC (Virtual Private Cloud)
resource "aws_vpc" "mcan97-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "mcan97-vpc"
  }
}

# Public Subnet (Alt ağ)
resource "aws_subnet" "mcan97-public-subnet-01" {
  vpc_id                  = aws_vpc.mcan97-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"
  tags = {
    Name = "mcan97-public-subnet-01"
  }
}

resource "aws_subnet" "mcan97-public-subnet-02" {
  vpc_id                  = aws_vpc.mcan97-vpc.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1b"
  tags = {
    Name = "mcan97-public-subnet-02"
  }
}

# Internet Gateway (İnternet geçidi)
resource "aws_internet_gateway" "mcan97-igw" {
  vpc_id = aws_vpc.mcan97-vpc.id
  tags = {
    Name = "mcan97-igw"
  }
}

# Internet Gateway (İnternet geçidi)
resource "aws_internet_gateway" "mcan97-igw" {
  vpc_id = aws_vpc.mcan97-vpc.id
  tags = {
    Name = "mcan97-igw"
  }
}

# Route Table (Yol tablosu)
resource "aws_route_table" "mcan97-public-rt" {
  vpc_id = aws_vpc.mcan97-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mcan97-igw.id
  }
  tags = {
    Name = "mcan97-public-rt"
  }
}

# Route Table Association (Yol tablosu ilişkisi)
resource "aws_route_table_association" "mcan97-rta-public-subnet-01" {
  subnet_id      = aws_subnet.mcan97-public-subnet-01.id
  route_table_id = aws_route_table.mcan97-public-rt.id
}

resource "aws_route_table_association" "mcan97-rta-public-subnet-02" {
  subnet_id      = aws_subnet.mcan97-public-subnet-02.id
  route_table_id = aws_route_table.mcan97-public-rt.id
}

# Güvenlik Grubu Modülü
module "sgs" {
  source = "../sg_eks"
  vpc_id = aws_vpc.mcan97-vpc.id
}

# EKS Modülü
module "eks" {
  source     = "../eks"
  vpc_id     = aws_vpc.mcan97-vpc.id
  subnet_ids = [
    aws_subnet.mcan97-public-subnet-01.id,
    aws_subnet.mcan97-public-subnet-02.id
  ]
  sg_ids = module.sgs.security_group_public
}
