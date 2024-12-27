provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "demo-server" {
   ami = "ami-0e54671bdf3c8ed8d"  # AMI ID, us-east-1 bölgesine ait olmalı
   instance_type = "t2.micro"
   key_name      = "mcan97"  # AWS'de önceden oluşturulmuş bir keypair olmalı
}