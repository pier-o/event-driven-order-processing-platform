output "vpc_id" {
  description = "The VPC ID"
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}

output "private_route_table_ids" {
  description = "The IDs of the route tables"
  value = [
    aws_route_table.private_a.id,
    aws_route_table.private_b.id
  ]
}