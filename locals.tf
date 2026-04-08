data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  selected_primary_az = (
    var.primary_az != ""
    ? var.primary_az
    : data.aws_availability_zones.available.names[0]
  )

  selected_inspection_azs = (
    length(var.inspection_azs) == 2
    ? var.inspection_azs
    : slice(data.aws_availability_zones.available.names, 0, 2)
  )

  app1_name       = "${var.project_name}-${var.environment}-app1"
  app2_name       = "${var.project_name}-${var.environment}-app2"
  inspection_name = "${var.project_name}-${var.environment}-inspection"
  tgw_name        = "${var.project_name}-${var.environment}-tgw"

  # Check Point module creates tgw subnets using the suffix numbers in this map.
  inspection_tgw_subnet_suffixes = {
    (local.selected_inspection_azs[0]) = "5"
    (local.selected_inspection_azs[1]) = "6"
  }

  # Derive these from the inspection VPC CIDR so they follow tfvars changes.
  checkpoint_nat_gw_subnet_1_cidr = cidrsubnet(var.inspection_vpc_cidr, 8, 13)
  checkpoint_nat_gw_subnet_2_cidr = cidrsubnet(var.inspection_vpc_cidr, 8, 23)
  checkpoint_gwlbe_subnet_1_cidr  = cidrsubnet(var.inspection_vpc_cidr, 8, 14)
  checkpoint_gwlbe_subnet_2_cidr  = cidrsubnet(var.inspection_vpc_cidr, 8, 24)

  # Allow key files with comments; extract only the OpenSSH public key line.
  public_key_lines = [
    for line in split("\n", file(var.public_key_path)) : trimspace(line)
    if can(regex("^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp(256|384|521))\\s+", trimspace(line)))
  ]
  public_key_material = length(local.public_key_lines) > 0 ? local.public_key_lines[0] : ""

  windows_public_key_lines = var.windows_public_key_path == "" ? [] : [
    for line in split("\n", file(var.windows_public_key_path)) : trimspace(line)
    if can(regex("^ssh-rsa\\s+", trimspace(line)))
  ]
  windows_public_key_material = length(local.windows_public_key_lines) > 0 ? local.windows_public_key_lines[0] : ""

  # Extract management server IP from nested tuple structure
  management_server_public_ip = try(
    flatten(module.checkpoint_inspection.management_public_ip)[0],
    ""
  )
}
