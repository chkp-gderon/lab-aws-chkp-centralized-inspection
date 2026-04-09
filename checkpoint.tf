resource "aws_key_pair" "lab" {
  key_name   = var.key_pair_name
  public_key = local.public_key_material

  lifecycle {
    precondition {
      condition     = local.public_key_material != ""
      error_message = "No valid OpenSSH public key line found in public_key_path. Ensure the file contains a line starting with ssh-rsa, ssh-ed25519, or ecdsa-sha2-..."
    }
  }
}

resource "aws_key_pair" "windows" {
  count = var.windows_public_key_path != "" ? 1 : 0

  key_name   = "${var.key_pair_name}-windows"
  public_key = local.windows_public_key_material

  lifecycle {
    precondition {
      condition     = local.windows_public_key_material != ""
      error_message = "windows_public_key_path must point to a file containing a valid ssh-rsa public key line."
    }
  }
}

module "checkpoint_inspection" {
  source  = "CheckPointSW/cloudguard-network-security/aws//modules/tgw_gwlb_master"
  version = "1.0.10"

  # Inspection VPC in two AZs for the firewall stack.
  vpc_cidr             = var.inspection_vpc_cidr
  subnets_bit_length   = 8
  availability_zones   = local.selected_inspection_azs
  number_of_AZs        = 2
  public_subnets_map   = { (local.selected_inspection_azs[0]) = "1", (local.selected_inspection_azs[1]) = "2" }
  tgw_subnets_map      = local.inspection_tgw_subnet_suffixes
  nat_gw_subnet_1_cidr = local.checkpoint_nat_gw_subnet_1_cidr
  nat_gw_subnet_2_cidr = local.checkpoint_nat_gw_subnet_2_cidr
  gwlbe_subnet_1_cidr  = local.checkpoint_gwlbe_subnet_1_cidr
  gwlbe_subnet_2_cidr  = local.checkpoint_gwlbe_subnet_2_cidr

  key_name                         = aws_key_pair.lab.key_name
  gateway_load_balancer_name       = "chkp-gwlb-lab"
  target_group_name                = "chkp-gwlb-tg"
  enable_cross_zone_load_balancing = true

  gateway_name                           = "chkp-gw"
  gateway_instance_type                  = var.checkpoint_gateway_instance_type
  minimum_group_size                     = 2
  maximum_group_size                     = 2
  gateway_version                        = var.checkpoint_gateway_version
  gateway_password_hash                  = local.effective_gateway_password_hash
  gateway_maintenance_mode_password_hash = local.effective_gateway_maintenance_password_hash
  gateway_SICKey                         = var.checkpoint_gateway_sic_key
  gateways_provision_address_type        = "private"
  allocate_public_IP                     = false
  enable_cloudwatch                      = false

  management_deploy                         = true
  management_instance_type                  = var.checkpoint_management_instance_type
  management_version                        = var.checkpoint_management_version
  management_password_hash                  = local.effective_management_password_hash
  management_maintenance_mode_password_hash = local.effective_management_maintenance_password_hash
  admin_cidr                                = var.checkpoint_admin_cidr
  gateways_addresses                        = var.checkpoint_gateways_addresses_cidr

  configuration_template   = "gwlb-lab"
  management_server        = "chkp-mgmt-lab"
  gateways_policy          = "Standard"
  gateway_management       = "Locally managed"
  enable_volume_encryption = true
  volume_size              = 200
  volume_type              = "gp3"
}

# Discover inspection VPC/subnets created by the official Check Point module.
data "aws_vpc" "inspection" {
  filter {
    name   = "cidr-block"
    values = [var.inspection_vpc_cidr]
  }

  depends_on = [module.checkpoint_inspection]
}

data "aws_subnets" "inspection_tgw" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.inspection.id]
  }

  filter {
    name   = "tag:Name"
    values = ["tgw subnet 5", "tgw subnet 6"]
  }

  depends_on = [module.checkpoint_inspection]
}
