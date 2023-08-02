# create vpc
resource "aws_vpc" "vpc" {
  cidr_block              = var.vpc_cidr
  instance_tenancy        = "default"
  enable_dns_hostnames    = true

  tags      = {
    Name    = "${var.project_name}-vpc"
  }
}

# create internet gateway and attach it to vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id    = aws_vpc.vpc.id

  tags      = {
    Name    = "${var.project_name}-igw"
  }
}

# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

# create public subnet az1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags      = {
    Name    = "public subnet az1"
  }
}

# create public subnet az2
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags      = {
    Name    = "public subnet az2"
  }
}

# create route table and add public route
resource "aws_route_table" "public_route_table" {
  vpc_id       = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags       = {
    Name     = "public route table"
  }
}

# associate public subnet az1 to "public route table"
resource "aws_route_table_association" "public_subnet_az1_route_table_association" {
  subnet_id           = aws_subnet.public_subnet_az1.id
  route_table_id      = aws_route_table.public_route_table.id
}

# associate public subnet az2 to "public route table"
resource "aws_route_table_association" "public_subnet_az2_route_table_association" {
  subnet_id           = aws_subnet.public_subnet_az2.id
  route_table_id      = aws_route_table.public_route_table.id
}

# create private app subnet az1
resource "aws_subnet" "private_app_subnet_az1" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.private_app_subnet_az1_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "private app subnet az1"
  }
}

# create private app subnet az2
resource "aws_subnet" "private_app_subnet_az2" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.private_app_subnet_az2_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "private app subnet az2"
  }
}

# create private database subnet az1
resource "aws_subnet" "private_database_subnet_az1" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.private_database_subnet_az1_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "database subnet az1"
  }
}

# create private database subnet az2
resource "aws_subnet" "private_database_subnet_az2" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.private_database_subnet_az2_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "database subnet az2"
  }
}

# NAT gateway
resource "aws_eip" "eip_for_natgateway_az1"{
  vpc = true
  depends_on = [ aws_internet_gateway.internet_gateway ]
  tags    ={
    Name  = "elastic ip az1"
  }
}

resource "aws_eip" "eip_for_natgateway_az2"{
  vpc = true
  depends_on = [ aws_internet_gateway.internet_gateway ]
  tags    ={
    Name  = "elastic ip az2"
  }
}

#NAT gateway for public subnet in AZ1
resource "aws_nat_gateway" "nat_gateway_az1"{
  allocation_id = aws_eip.eip_for_natgateway_az1.id
  subnet_id = aws_subnet.public_subnet_az1.id

  tags   ={
    Name = "nat gateway az1"
  }
  depends_on = [ aws_internet_gateway.internet_gateway ]
}

#NAT gateway for public subnet in AZ2
resource "aws_nat_gateway" "nat_gateway_az2"{
  allocation_id = aws_eip.eip_for_natgateway_az2.id
  subnet_id = aws_subnet.public_subnet_az2.id

  tags   ={
    Name = "nat gateway az2"
  }
  depends_on = [ aws_internet_gateway.internet_gateway ]
}

# create private route table az1 and add route through nat gateway az1
resource "aws_route_table" "private_route_table_az1" {
  vpc_id            = aws_vpc.vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat_gateway_az1.id
  }

  tags   = {
    Name = "private route table"
  }
}

# associate private app subnet az1 with private route table az1
resource "aws_route_table_association" "private_app_subnet_az1_route_table_az1_association" {
  subnet_id         = aws_subnet.private_app_subnet_az1.id
  route_table_id    = aws_route_table.private_route_table_az1.id 
}

# associate private data subnet az1 with private route table az1
resource "aws_route_table_association" "private_database_subnet_az1_route_table_az1_association" {
  subnet_id         = aws_subnet.private_database_subnet_az1.id
  route_table_id    = aws_route_table.private_route_table_az1.id
}

# create private route table az2 and add route through nat gateway az2
resource "aws_route_table" "private_route_table_az2" {
  vpc_id            = aws_vpc.vpc.id 

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat_gateway_az2.id 
  }

  tags   = {
    Name = "private rote table az2"
  }
}

# associate private app subnet az2 with private route table az2
resource "aws_route_table_association" "private_app_subnet_az2_route_table_az2_association" {
  subnet_id         = aws_subnet.private_app_subnet_az2.id 
  route_table_id    = aws_route_table.private_route_table_az2.id 
}

# associate private data subnet az2 with private route table az2
resource "aws_route_table_association" "private_database_subnet_az2_route_table_az2_association" {
  subnet_id         = aws_subnet.private_database_subnet_az2.id 
  route_table_id    = aws_route_table.private_route_table_az2.id 
}

#Network ACL
resource "aws_network_acl" "NACL" {
  vpc_id = aws_vpc.vpc.id
}

#Rules for NACL
resource "aws_network_acl_rule" "ssh" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 100
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
  from_port       = 22
  to_port         = 22 
}

resource "aws_network_acl_rule" "http" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 110
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
  from_port       = 80
  to_port         = 80 
}

resource "aws_network_acl_rule" "apache" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 120
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
  from_port       = 8080
  to_port         = 8080 
}

resource "aws_network_acl_rule" "postgresdb" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 130
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
  from_port       = 5432
  to_port         = 5432 
}

resource "aws_network_acl_rule" "all" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 140
  egress          = false
  protocol        = "-1"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "httpe" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 200
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
  from_port       = 80
  to_port         = 80 
}

resource "aws_network_acl_rule" "sshe" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 210
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
  from_port       = 22
  to_port         = 22 
}

resource "aws_network_acl_rule" "apachee" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 220
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
  from_port       = 8080
  to_port         = 8080
}

resource "aws_network_acl_rule" "postgresdbe" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 230
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
  from_port       = 5432
  to_port         = 5432
}

resource "aws_network_acl_rule" "alle" {
  network_acl_id  = aws_network_acl.NACL.id
  rule_number     = 240
  egress          = true
  protocol        = "-1"
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"
}

#Network ACL association
resource "aws_network_acl_association" "public1" {
  subnet_id       = aws_subnet.public_subnet_az1.id
  network_acl_id  = aws_network_acl.NACL.id
}

resource "aws_network_acl_association" "public2" {
  subnet_id       = aws_subnet.public_subnet_az2.id
  network_acl_id  = aws_network_acl.NACL.id
}

resource "aws_network_acl_association" "private1" {
  subnet_id       = aws_subnet.private_app_subnet_az1.id
  network_acl_id  = aws_network_acl.NACL.id
}

resource "aws_network_acl_association" "private2" {
  subnet_id       = aws_subnet.private_app_subnet_az2.id
  network_acl_id  = aws_network_acl.NACL.id
}

resource "aws_network_acl_association" "private3" {
  subnet_id       = aws_subnet.private_database_subnet_az1.id
  network_acl_id  = aws_network_acl.NACL.id
}

resource "aws_network_acl_association" "private4" {
  subnet_id       = aws_subnet.private_database_subnet_az2.id
  network_acl_id  = aws_network_acl.NACL.id
}

