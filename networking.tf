resource "aws_vpc" "app1" {
  cidr_block           = var.app1_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = local.app1_name
  }
}

resource "aws_vpc" "app2" {
  cidr_block           = var.app2_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = local.app2_name
  }
}

resource "aws_internet_gateway" "app1" {
  vpc_id = aws_vpc.app1.id

  tags = {
    Name = "${local.app1_name}-igw"
  }
}

resource "aws_subnet" "app1_public" {
  vpc_id                  = aws_vpc.app1.id
  cidr_block              = cidrsubnet(var.app1_vpc_cidr, 8, 1)
  availability_zone       = local.selected_primary_az
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.app1_name}-public"
  }
}

resource "aws_subnet" "app1_private" {
  vpc_id            = aws_vpc.app1.id
  cidr_block        = cidrsubnet(var.app1_vpc_cidr, 8, 2)
  availability_zone = local.selected_primary_az

  tags = {
    Name = "${local.app1_name}-private"
  }
}

resource "aws_subnet" "app1_tgw" {
  vpc_id            = aws_vpc.app1.id
  cidr_block        = cidrsubnet(var.app1_vpc_cidr, 8, 3)
  availability_zone = local.selected_primary_az

  tags = {
    Name = "${local.app1_name}-tgw"
  }
}

resource "aws_subnet" "app2_private" {
  vpc_id            = aws_vpc.app2.id
  cidr_block        = cidrsubnet(var.app2_vpc_cidr, 8, 1)
  availability_zone = local.selected_primary_az

  tags = {
    Name = "${local.app2_name}-private"
  }
}

resource "aws_subnet" "app2_tgw" {
  vpc_id            = aws_vpc.app2.id
  cidr_block        = cidrsubnet(var.app2_vpc_cidr, 8, 2)
  availability_zone = local.selected_primary_az

  tags = {
    Name = "${local.app2_name}-tgw"
  }
}

resource "aws_route_table" "app1_public" {
  vpc_id = aws_vpc.app1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app1.id
  }

  tags = {
    Name = "${local.app1_name}-public-rt"
  }
}

resource "aws_route_table_association" "app1_public" {
  subnet_id      = aws_subnet.app1_public.id
  route_table_id = aws_route_table.app1_public.id
}

resource "aws_route_table" "app1_private" {
  vpc_id = aws_vpc.app1.id

  tags = {
    Name = "${local.app1_name}-private-rt"
  }
}

resource "aws_route_table_association" "app1_private" {
  subnet_id      = aws_subnet.app1_private.id
  route_table_id = aws_route_table.app1_private.id
}

resource "aws_route_table" "app2_private" {
  vpc_id = aws_vpc.app2.id

  tags = {
    Name = "${local.app2_name}-private-rt"
  }
}

resource "aws_route_table_association" "app2_private" {
  subnet_id      = aws_subnet.app2_private.id
  route_table_id = aws_route_table.app2_private.id
}

resource "aws_ec2_transit_gateway" "central" {
  description                     = "Central TGW for Check Point inspection lab"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name = local.tgw_name
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "inspection" {
  subnet_ids = data.aws_subnets.inspection_tgw.ids
  vpc_id     = data.aws_vpc.inspection.id

  transit_gateway_id = aws_ec2_transit_gateway.central.id

  appliance_mode_support = "enable"
  dns_support            = "enable"

  tags = {
    Name = "${local.tgw_name}-inspection"
  }

  depends_on = [module.checkpoint_inspection]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app1" {
  subnet_ids         = [aws_subnet.app1_tgw.id]
  vpc_id             = aws_vpc.app1.id
  transit_gateway_id = aws_ec2_transit_gateway.central.id

  dns_support = "enable"

  tags = {
    Name = "${local.tgw_name}-app1"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app2" {
  subnet_ids         = [aws_subnet.app2_tgw.id]
  vpc_id             = aws_vpc.app2.id
  transit_gateway_id = aws_ec2_transit_gateway.central.id

  dns_support = "enable"

  tags = {
    Name = "${local.tgw_name}-app2"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spokes" {
  transit_gateway_id = aws_ec2_transit_gateway.central.id

  tags = {
    Name = "${local.tgw_name}-spokes-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.central.id

  tags = {
    Name = "${local.tgw_name}-inspection-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "app1_to_spokes" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}

resource "aws_ec2_transit_gateway_route_table_association" "app2_to_spokes" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}

resource "aws_ec2_transit_gateway_route_table_association" "inspection_to_inspection_rt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
  replace_existing_association   = true
}

# Spoke table sends inter-VPC and north/south traffic to inspection attachment.
resource "aws_ec2_transit_gateway_route" "spokes_to_app1" {
  destination_cidr_block         = var.app1_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}

resource "aws_ec2_transit_gateway_route" "spokes_to_app2" {
  destination_cidr_block         = var.app2_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}

resource "aws_ec2_transit_gateway_route" "spokes_default" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}

# Inspection table returns traffic from appliances to the correct app attachment.
resource "aws_ec2_transit_gateway_route" "inspection_to_app1" {
  destination_cidr_block         = var.app1_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

resource "aws_ec2_transit_gateway_route" "inspection_to_app2" {
  destination_cidr_block         = var.app2_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

resource "aws_route" "app1_private_default_to_tgw" {
  route_table_id         = aws_route_table.app1_private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.central.id
}

resource "aws_route" "app1_private_to_app2" {
  route_table_id         = aws_route_table.app1_private.id
  destination_cidr_block = var.app2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.central.id
}

resource "aws_route" "app1_public_to_app2" {
  route_table_id         = aws_route_table.app1_public.id
  destination_cidr_block = var.app2_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.central.id
}

resource "aws_route" "app2_private_default_to_tgw" {
  route_table_id         = aws_route_table.app2_private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.central.id
}

resource "aws_route" "app2_private_to_app1" {
  route_table_id         = aws_route_table.app2_private.id
  destination_cidr_block = var.app1_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.central.id
}
