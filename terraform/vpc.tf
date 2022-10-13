# VPC

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true" 
  enable_dns_hostnames = "true" 
  instance_tenancy     = "default"
    
  tags = {
    Name = "vpc"
  }
}

# SUBNETS

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = local.availability_zone_a
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "SubnetA"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = local.availability_zone_b
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "SubnetB"
  }
}

# Internet Gateway. Permite a la VPC conectarse a Internet
resource "aws_internet_gateway" "gateway" {
    vpc_id = aws_vpc.vpc.id
    
    tags = {
        Name = "Gateway"
    }
}

# Tabla de enrutamiento para las subnets. Para que sean accesibles desde Internet
resource "aws_route_table" "crt" {
    vpc_id = aws_vpc.vpc.id
    
    route {
        cidr_block = "0.0.0.0/0" 
        gateway_id = "${aws_internet_gateway.gateway.id}" 
    }
    
    tags = {
        Name = "crt"
    }
}

# Asociación de la tabla de enrutamineto a las subnets
resource "aws_route_table_association" "ctr-subnet-a"{
    subnet_id      = aws_subnet.subnet_a.id
    route_table_id = aws_route_table.crt.id
}

resource "aws_route_table_association" "ctr-subnet-b"{
    subnet_id      = aws_subnet.subnet_b.id
    route_table_id = aws_route_table.crt.id
}