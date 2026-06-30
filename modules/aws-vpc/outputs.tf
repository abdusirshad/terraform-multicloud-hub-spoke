output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "Primary CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = [for s in aws_subnet.private : s.id]
}

output "internet_gateway_id" {
  description = "ID of the internet gateway (null when no public subnets are defined)."
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway (null when disabled)."
  value       = local.create_nat ? aws_nat_gateway.this[0].id : null
}
