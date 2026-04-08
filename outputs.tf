output "selected_primary_az" {
  description = "Primary AZ used for app VPCs and test instances"
  value       = local.selected_primary_az
}

output "selected_inspection_azs" {
  description = "AZs used by Check Point inspection stack"
  value       = local.selected_inspection_azs
}

output "transit_gateway_id" {
  description = "Central TGW ID"
  value       = aws_ec2_transit_gateway.central.id
}

output "inspection_vpc_id" {
  description = "Inspection VPC ID created by Check Point module"
  value       = data.aws_vpc.inspection.id
}

output "app1_vpc_id" {
  description = "App1 VPC ID"
  value       = aws_vpc.app1.id
}

output "app2_vpc_id" {
  description = "App2 VPC ID"
  value       = aws_vpc.app2.id
}

output "linux_bastion_public_ip" {
  description = "Public IP of Linux bastion"
  value       = aws_instance.linux_bastion.public_ip
}

output "linux1_private_ip" {
  description = "Private IP of Linux1 in App1 VPC"
  value       = aws_instance.linux1.private_ip
}

output "linux2_private_ip" {
  description = "Private IP of Linux2 in App2 VPC"
  value       = aws_instance.linux2.private_ip
}

output "checkpoint_management_public_ip" {
  description = "Public IP of deployed Check Point management server"
  value       = module.checkpoint_inspection.management_public_ip
}

output "checkpoint_gwlb_service_name" {
  description = "Service name for Check Point GWLB"
  value       = module.checkpoint_inspection.gwlb_service_name
}

output "checkpoint_management_access" {
  description = "Check Point Management Server Access Information"
  value = {
    public_ip  = local.management_server_public_ip
    access_url = local.management_server_public_ip != "" ? "https://${local.management_server_public_ip}/smartconsole" : "Access URL will be available after deployment"
    instructions = (
      local.management_server_public_ip != ""
      ? "Access the Check Point Management Server via SmartConsole at https://${local.management_server_public_ip}/smartconsole"
      : "Management server is still being provisioned. Public IP will appear here once available."
    )
  }
}
