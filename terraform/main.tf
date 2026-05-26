resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.project_name}-vpc"
    }
}

resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_1_cidr
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.project_name}-public-subnet-1"
    }
    }

resource "aws_subnet" "public_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_2_cidr
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.project_name}-public-subnet-2"
    }
}

resource "aws_subnet" "private_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_1_cidr
    availability_zone = "ap-south-1a"
    tags = {
        Name = "${var.project_name}-private-subnet-1"
    }
}


resource "aws_subnet" "private_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_2_cidr
    availability_zone = "ap-south-1b"
    tags = {
        Name = "${var.project_name}-private-subnet-2"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.project_name}-igw"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "${var.project_name}-public-rt"
    }
}

resource "aws_route_table_association" "public_1" {
    subnet_id = aws_subnet.public_1.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
    domain = "vpc"
    tags = {
        Name = "${var.project_name}-nat-eip"
    }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    }
    tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_1" {
    subnet_id = aws_subnet.private_1.id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
    subnet_id = aws_subnet.private_2.id
    route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "public_sg" {
  name        = "${var.project_name}-public-sg"
  description = "Public access security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-public-sg"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "${var.project_name}-private-sg"
  description = "Private internal security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Internal VPC Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-private-sg"
  }
}
