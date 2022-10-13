provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}

locals {
  availability_zone_a = "us-east-1a"             # Nombre zona de disponibilidad
  availability_zone_b = "us-east-1b"             # Nombre zona de disponibilidad
  instance_type       = "t2.micro"               # Tipo de instancia
  ami                 = "ami-04430ccc36585eb1d"  # AMI de la instancia (WordPress de Bitnami por defecto, Usuario Linux: bitnami)
  
  # Valores opcionales para listener HTTPS
  # certificate_arn   = ""
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
}

# INSTANCIA WORDPRESS 

resource "aws_instance" "wordpress" {
  ami                    = local.ami
  instance_type          = local.instance_type
  availability_zone      = local.availability_zone_a
  subnet_id              = aws_subnet.subnet_a.id
  vpc_security_group_ids = [aws_security_group.WP_sg.id]
  
  # Llave SSH
  key_name = "ssh-key"

  tags = {
    Name = "Instacia-WordPress"
  }
}

# Mostrar IP pública de la instancia al desplegar
output "IP_Instancia_SSH" {
  value = ["${aws_instance.wordpress.*.public_ip}"]
}

# Mostrar DNS del balanceador de carga al desplegar
output "DNS_Balanceador" {
  value = ["${aws_lb.LB.*.dns_name}"]
}

# SSH KEY

resource "aws_key_pair" "llave-ssh" {
  key_name   = "ssh-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh-key" {
    content  = tls_private_key.rsa.private_key_pem
    filename = "./keys/ssh-key"
}
