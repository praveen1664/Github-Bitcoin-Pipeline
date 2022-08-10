data "aws_availability_zones" "available" {
  state = "available"
}

## Create EIP to attach to NAT Gateway ##

resource "aws_eip" "nat" {
  count = "2"
 # vpc      = true
}



#data "aws_subnet" "public_subnets" {
#  count = "${length(data.aws_availability_zones.available.names)}"
#}

resource "aws_vpc" "vpc-network" {
   cidr_block = var.vpc_cidr_block
   enable_dns_hostnames = true
   tags = {
   Name = "main"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc-network.id
  tags = {
    Name = "${var.env}-igw"
  }
}

  resource "aws_nat_gateway" "nat" {
  count     = length(var.public_subnet_cidr_blocks)
  subnet_id  = aws_subnet.public[count.index].id
  allocation_id = "${aws_eip.nat.*.id[count.index]}"
  tags = {
    Name = "${var.env}-nat"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.vpc-network.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name  = "public_subnet_${count.index}"
    Stack = count.index
  }
}

resource "aws_subnet" "private" {
  count                   = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.vpc-network.id
  cidr_block              = var.private_subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name  = "private_subnet_${count.index}"
    Stack = count.index
  }
}

resource "aws_route_table_association" "public_crt_public_subnet" {
  count = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_custom_route_table.id
}

resource "aws_route_table" "public_custom_route_table" {
  vpc_id = aws_vpc.vpc-network.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-${var.env}"
  }
}

resource "aws_route_table" "private_custom_route_table" {
  vpc_id = aws_vpc.vpc-network.id
  count  = length(var.private_subnet_cidr_blocks)

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "private-${var.env}"
  }
}

resource "aws_route_table_association" "private_crt_public_subnet" {
  count         = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  #route_table_id = aws_route_table.private_custom_route_table.id
  route_table_id = element(aws_route_table.private_custom_route_table.*.id, count.index)
}

#Creating security group for EFS

## Creating EFS ##

resource "aws_efs_file_system" "bitcoin" {
creation_token = "bitcoin"
performance_mode = "generalPurpose"
throughput_mode = "bursting"
  tags = {
    Name = "ECS-EFS-FS"
  }
}


# This resource will destroy (potentially immediately) after null_resource.next
resource "null_resource" "previous" {
  depends_on = [
    aws_efs_file_system.bitcoin
  ]
}

resource "time_sleep" "wait_200_seconds" {
  depends_on = [null_resource.previous, aws_efs_file_system.bitcoin]

  create_duration = "500s"
}

# This resource will create (at least) 30 seconds after null_resource.previous
resource "null_resource" "next" {
  depends_on = [time_sleep.wait_200_seconds, null_resource.previous, aws_efs_file_system.bitcoin]
}

resource "aws_efs_mount_target" "mount" {
  file_system_id = aws_efs_file_system.bitcoin.id
  count = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  security_groups = [var.sgsid_ecs_efs]
  depends_on = [
    null_resource.next, time_sleep.wait_200_seconds, null_resource.previous, aws_efs_file_system.bitcoin
  ]
  /* tags = {
    Name = "ECS-EFS-MNT"
  } */
}



