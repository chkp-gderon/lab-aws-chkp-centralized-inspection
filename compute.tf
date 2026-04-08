data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "linux_bastion" {
  name        = "${local.app1_name}-linux-bastion-sg"
  description = "Allow SSH access to Linux bastion"
  vpc_id      = aws_vpc.app1.id

  ingress {
    description = "SSH from allowed admin network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.app1_name}-linux-bastion-sg"
  }
}

resource "aws_security_group" "linux_app1" {
  name        = "${local.app1_name}-linux-sg"
  description = "Allow SSH from App1 VPC"
  vpc_id      = aws_vpc.app1.id

  ingress {
    description = "SSH from App1 VPC (including bastion)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.app1_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.app1_name}-linux-sg"
  }
}

resource "aws_security_group" "linux_app2" {
  name        = "${local.app2_name}-linux-sg"
  description = "Allow SSH from App1 VPC (bastion source)"
  vpc_id      = aws_vpc.app2.id

  ingress {
    description = "SSH from App1 VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.app1_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.app2_name}-linux-sg"
  }
}

resource "aws_instance" "linux_bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.linux_instance_type
  subnet_id                   = aws_subnet.app1_public.id
  vpc_security_group_ids      = [aws_security_group.linux_bastion.id]
  key_name                    = aws_key_pair.lab.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${local.app1_name}-linux-bastion"
    Role = "bastion"
  }
}

resource "aws_instance" "linux1" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.linux_instance_type
  subnet_id              = aws_subnet.app1_private.id
  vpc_security_group_ids = [aws_security_group.linux_app1.id]
  key_name               = aws_key_pair.lab.key_name

  tags = {
    Name = "${local.app1_name}-linux1"
    Role = "workload"
  }
}

resource "aws_instance" "linux2" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.linux_instance_type
  subnet_id              = aws_subnet.app2_private.id
  vpc_security_group_ids = [aws_security_group.linux_app2.id]
  key_name               = aws_key_pair.lab.key_name

  tags = {
    Name = "${local.app2_name}-linux2"
    Role = "workload"
  }
}
