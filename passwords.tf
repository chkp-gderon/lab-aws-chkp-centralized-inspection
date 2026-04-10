# Auto-generate random passwords and convert to SHA-512 hashes for Check Point
# Set generate_random_passwords to true to enable automatic password generation
# Otherwise, provide your own hashes in terraform.tfvars

variable "generate_random_passwords" {
  description = "If true, generate random passwords automatically. If false, use hashes from terraform.tfvars"
  type        = bool
  default     = false
}

# Generate random passwords (32 chars with special characters)
resource "random_password" "gateway_password" {
  length  = 32
  special = true
}

resource "random_password" "gateway_maintenance_password" {
  length  = 32
  special = true
}

resource "random_password" "management_password" {
  length  = 32
  special = true
}

resource "random_password" "management_maintenance_password" {
  length  = 32
  special = true
}

locals {
  password_hash_dir = "${path.module}/.generated"

  password_hashes_ready = alltrue([
    fileexists("${path.module}/.generated/gateway_hash.txt"),
    fileexists("${path.module}/.generated/gateway_maint_hash.txt"),
    fileexists("${path.module}/.generated/management_hash.txt"),
    fileexists("${path.module}/.generated/management_maint_hash.txt")
  ])
}

# Convert random passwords to SHA-512 hashes using openssl
resource "null_resource" "generate_password_hashes" {
  # Bootstrap behavior: generate hash files only when they do not already exist.
  count = var.generate_random_passwords && !local.password_hashes_ready ? 1 : 0

  triggers = {
    gateway_password                = random_password.gateway_password.result
    gateway_maintenance_password    = random_password.gateway_maintenance_password.result
    management_password             = random_password.management_password.result
    management_maintenance_password = random_password.management_maintenance_password.result
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p '${local.password_hash_dir}'
      echo '${random_password.gateway_password.result}' | openssl passwd -6 -stdin > '${local.password_hash_dir}/gateway_hash.txt'
      echo '${random_password.gateway_maintenance_password.result}' | openssl passwd -6 -stdin > '${local.password_hash_dir}/gateway_maint_hash.txt'
      echo '${random_password.management_password.result}' | openssl passwd -6 -stdin > '${local.password_hash_dir}/management_hash.txt'
      echo '${random_password.management_maintenance_password.result}' | openssl passwd -6 -stdin > '${local.password_hash_dir}/management_maint_hash.txt'
    EOT
  }
}

# Read generated hashes
data "local_file" "gateway_password_hash" {
  count      = var.generate_random_passwords ? 1 : 0
  filename   = "${local.password_hash_dir}/gateway_hash.txt"
  depends_on = [null_resource.generate_password_hashes]
}

data "local_file" "gateway_maintenance_password_hash" {
  count      = var.generate_random_passwords ? 1 : 0
  filename   = "${local.password_hash_dir}/gateway_maint_hash.txt"
  depends_on = [null_resource.generate_password_hashes]
}

data "local_file" "management_password_hash" {
  count      = var.generate_random_passwords ? 1 : 0
  filename   = "${local.password_hash_dir}/management_hash.txt"
  depends_on = [null_resource.generate_password_hashes]
}

data "local_file" "management_maintenance_password_hash" {
  count      = var.generate_random_passwords ? 1 : 0
  filename   = "${local.password_hash_dir}/management_maint_hash.txt"
  depends_on = [null_resource.generate_password_hashes]
}

# Combine generated hashes with tfvars-provided hashes
locals {
  effective_gateway_password_hash = var.generate_random_passwords && var.checkpoint_gateway_password_hash == "" ? trimspace(data.local_file.gateway_password_hash[0].content) : var.checkpoint_gateway_password_hash

  effective_gateway_maintenance_password_hash = var.generate_random_passwords && var.checkpoint_gateway_maintenance_mode_password_hash == "" ? trimspace(data.local_file.gateway_maintenance_password_hash[0].content) : var.checkpoint_gateway_maintenance_mode_password_hash

  effective_management_password_hash = var.generate_random_passwords && var.checkpoint_management_password_hash == "" ? trimspace(data.local_file.management_password_hash[0].content) : var.checkpoint_management_password_hash

  effective_management_maintenance_password_hash = var.generate_random_passwords && var.checkpoint_management_maintenance_mode_password_hash == "" ? trimspace(data.local_file.management_maintenance_password_hash[0].content) : var.checkpoint_management_maintenance_mode_password_hash
}

# Use these outputs to see the generated passwords
output "generated_passwords" {
  description = "Auto-generated random passwords (for reference only—change Check Point passwords post-deploy via console for security)"
  value = var.generate_random_passwords ? {
    gateway_password                = random_password.gateway_password.result
    gateway_maintenance_password    = random_password.gateway_maintenance_password.result
    management_password             = random_password.management_password.result
    management_maintenance_password = random_password.management_maintenance_password.result
  } : null
  sensitive = true
}

output "generated_password_hashes" {
  description = "Auto-generated SHA-512 hashes (currently being used by the deployment)"
  value = var.generate_random_passwords ? {
    gateway_password_hash                = local.effective_gateway_password_hash
    gateway_maintenance_password_hash    = local.effective_gateway_maintenance_password_hash
    management_password_hash             = local.effective_management_password_hash
    management_maintenance_password_hash = local.effective_management_maintenance_password_hash
  } : null
  sensitive = true
}
