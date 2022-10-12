provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

locals {
  subnet_a                   = ""                         # ID subnet A
  subnet_b                   = ""                         # ID subnet B
  availability_instance_zone = "us-east-1a"               # Nombre zona de disponibilidad
  instance_type              = "t2.micro"                 # Tipo de instancia
  vpc_id                     = ""                         # ID de la VPC
  ami                        = "ami-04430ccc36585eb1d"    # AMI de la instancia (WordPress de Bitnami por defecto)
  
  # Valores opcionales para listener HTTPS
  # certificate_arn   = ""
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
}

# INSTANCIA WORDPRESS 

resource "aws_instance" "wordpress" {
  ami               = local.ami
  instance_type     = local.instance_type
  availability_zone = local.availability_instance_zone
  security_groups   = [aws_security_group.WP_sg.name]

  tags = {
    Name = "Instacia-WordPress"
  }
}