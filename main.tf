data "aws_availability_zones" "zone_scaling" {}
#define AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = {
    Name = "dev_vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev_public_subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "dev_igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "dev_public_route_table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "public_security_group" {
  name        = "dev_public_security_group"
  description = "Allow inbound traffic from the internet"
  vpc_id      = aws_vpc.main_vpc.id


  ingress {
    description = "Allow inbound traffic from the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "dev_key_pair"
  public_key = file("~/.ssh/awskey.pub")
}

resource "aws_instance" "dev_node" {
  ami                         = "ami-08c40ec9ead489470"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_security_group.id]
  user_data                   = file("userdata.tpl")

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  tags = {
    Name = "dev_node"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip,
      user     = "ubuntu",
    identity = "~/.ssh/awskey" })

    interpreter = var.host_os == "windows" ? ["cmd", "/c"] : ["bash", "-c"]
  }
}

data "aws_autoscaling_groups" "groups" {
  filter {
    name   = "key"
    values = ["Team"]
  }

  filter {
    name   = "value"
    values = ["Pets"]
  }
}

resource "aws_autoscaling_notification" "slack_notifications" {
  group_names = data.aws_autoscaling_groups.groups.names

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = "TOPIC ARN"
}

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnet" "example" {
  for_each = toset(data.aws_subnets.example.ids)
  id       = each.value
}

output "subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.example : s.cidr_block]
}

data "aws_availability_zones" "available_zones" {
  state = "available"

}

resource "aws_lb_target_group" "target-group" {
  name     = "target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
}

resource "aws_lb" "load_balancer" {
  name               = "load-balancer"
  ip_address_type    = "ipv4"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_security_group.id]
  subnets            = data.aws_subnet_ids.public_subnet.ids

  enable_deletion_protection = false
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target-group.arn
    type             = "forward"
  }
}
 
 data "aws_subnet_ids" "public_subnet" {
  vpc_id = aws_vpc.main_vpc.id
 }