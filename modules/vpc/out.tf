output "vpcid" {
  value = aws_vpc.vpc-network.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}


output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "efs_id" {
  value = aws_efs_file_system.bitcoin.id
}

output "vpc_network" {
  value=aws_vpc.vpc-network.id
  
}