output "dev_ip" {
  value = aws_instance.dev_node.public_ip
}

output "dev_id" {
  value = aws_instance.dev_node.id
}

output "dev_key" {
  value = aws_key_pair.key_pair.key_name
}

output "dev_sg" {
  value = aws_security_group.public_security_group.id
}

output "dev_subnet" {
  value = aws_subnet.public_subnet.id
}

output "dev_rt" {
  value = aws_route_table.public_route_table.id
}

output "dev_igw" {
  value = aws_internet_gateway.internet_gateway.id
}

output "dev_vpc" {
  value = aws_vpc.main_vpc.id
}

