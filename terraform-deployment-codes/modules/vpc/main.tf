locals {
  public_count = length(var.public_subnet_cidrs)
  app_count    = length(var.private_app_subnet_cidrs)
  db_count     = length(var.private_db_subnet_cidrs)
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project}-${var.env}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project}-${var.env}-igw" }
}

# Public subnets
resource "aws_subnet" "public" {
  count = local.public_count
  vpc_id = aws_vpc.this.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-${var.env}-public-${count.index}" }
}

# Private app subnets
resource "aws_subnet" "private_app" {
  count = local.app_count
  vpc_id = aws_vpc.this.id
  cidr_block = var.private_app_subnet_cidrs[count.index]
  availability_zone = element(var.azs, count.index)
  tags = { Name = "${var.project}-${var.env}-private-app-${count.index}" }
}

# Private DB subnets
resource "aws_subnet" "private_db" {
  count = local.db_count
  vpc_id = aws_vpc.this.id
  cidr_block = var.private_db_subnet_cidrs[count.index]
  availability_zone = element(var.azs, count.index)
  tags = { Name = "${var.project}-${var.env}-private-db-${count.index}" }
}

# Public route table and association
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project}-${var.env}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count = local.public_count
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateways (one per AZ) - allocate EIP per NAT gateway
resource "aws_eip" "nat_eip" {
  count = local.public_count
  vpc = true
  tags = { Name = "${var.project}-${var.env}-nat-eip-${count.index}" }
}

resource "aws_nat_gateway" "nat" {
  count = local.public_count
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = { Name = "${var.project}-${var.env}-nat-${count.index}" }
  depends_on = [aws_internet_gateway.igw]
}

# Private route tables for app subnets (route through NAT in same AZ)
resource "aws_route_table" "private_app_rt" {
  count = local.app_count
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project}-${var.env}-private-app-rt-${count.index}" }
}

resource "aws_route" "private_app_default" {
  count = local.app_count
  route_table_id = aws_route_table.private_app_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "private_app_assoc" {
  count = local.app_count
  subnet_id = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app_rt[count.index].id
}

# Private route tables for db subnets (route through NAT as well if DB needs outbound)
resource "aws_route_table" "private_db_rt" {
  count = local.db_count
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project}-${var.env}-private-db-rt-${count.index}" }
}

resource "aws_route" "private_db_default" {
  count = local.db_count
  route_table_id = aws_route_table.private_db_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "private_db_assoc" {
  count = local.db_count
  subnet_id = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db_rt[count.index].id
}

output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "private_app_subnet_ids" { value = [for s in aws_subnet.private_app : s.id] }
output "private_db_subnet_ids" { value = [for s in aws_subnet.private_db : s.id] }
output "nat_gateway_ids" { value = [for n in aws_nat_gateway.nat : n.id] }
