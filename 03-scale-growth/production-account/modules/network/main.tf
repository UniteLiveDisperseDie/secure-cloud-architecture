# ──────────────────────────────────────────
# VPC
# ──────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project}-${var.environment}-vpc", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

# ──────────────────────────────────────────
# 서브넷 3계층 (Public / Private(ECS) / DB)
# ──────────────────────────────────────────
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_a
  availability_zone = var.availability_zone_a
  tags = { Name = "${var.project}-${var.environment}-public-a", Project = var.project, Environment = var.environment }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_b
  availability_zone = var.availability_zone_b
  tags = { Name = "${var.project}-${var.environment}-public-b", Project = var.project, Environment = var.environment }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = var.availability_zone_a
  tags = { Name = "${var.project}-${var.environment}-private-a", Project = var.project, Environment = var.environment }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = var.availability_zone_b
  tags = { Name = "${var.project}-${var.environment}-private-b", Project = var.project, Environment = var.environment }
}

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidr_a
  availability_zone = var.availability_zone_a
  tags = { Name = "${var.project}-${var.environment}-db-a", Project = var.project, Environment = var.environment }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidr_b
  availability_zone = var.availability_zone_b
  tags = { Name = "${var.project}-${var.environment}-db-b", Project = var.project, Environment = var.environment }
}

# ──────────────────────────────────────────
# IGW + NAT Gateway (AZ당 1개, 2개 총)
# ──────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-${var.environment}-igw", Project = var.project, Environment = var.environment }
}

resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags   = { Name = "${var.project}-${var.environment}-nat-eip-a" }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"
  tags   = { Name = "${var.project}-${var.environment}-nat-eip-b" }
}

resource "aws_nat_gateway" "a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.main]
  tags          = { Name = "${var.project}-${var.environment}-nat-a", Project = var.project, Environment = var.environment }
}

resource "aws_nat_gateway" "b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id
  depends_on    = [aws_internet_gateway.main]
  tags          = { Name = "${var.project}-${var.environment}-nat-b", Project = var.project, Environment = var.environment }
}

# ──────────────────────────────────────────
# 라우팅 테이블
# ──────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project}-${var.environment}-public-rt", Project = var.project, Environment = var.environment }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.a.id
  }

  tags = { Name = "${var.project}-${var.environment}-private-rt-a", Project = var.project, Environment = var.environment }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.b.id
  }

  tags = { Name = "${var.project}-${var.environment}-private-rt-b", Project = var.project, Environment = var.environment }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-${var.environment}-db-rt", Project = var.project, Environment = var.environment }
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.db.id
}
