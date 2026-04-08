# AWS Check Point Centralized Inspection Lab

This environment deploys a 100% Terraform-based AWS lab for testing Check Point CloudGuard inspection patterns:

- Inspection VPC with Check Point CloudGuard GWLB stack in 2 AZs (official module).
- 2 client VPCs (App1 and App2) in a single primary AZ.
- Central TGW connecting all 3 VPCs.
- 3 EC2 instances:
  - Linux bastion (public IP) in App1 VPC public subnet.
  - Linux1 (private IP) in App1 VPC private subnet.
  - Linux2 (private IP) in App2 VPC private subnet.

## Architecture Diagram

![AWS Check Point Centralized Inspection Architecture](./aws-lz-chkp-centralized-inspection.drawio.png)

This is a drawio diagram. To edit it, open [aws-lz-chkp-centralized-inspection.drawio](./aws-lz-chkp-centralized-inspection.drawio) with [diagrams.net](https://app.diagrams.net/) (File -> Open From -> GitHub).

## Official Check Point Module

This environment uses:

- `CheckPointSW/cloudguard-network-security/aws//modules/tgw_gwlb_master` version `1.0.10`

## Quick Start

1. Copy and edit tfvars:

```bash
cp terraform.tfvars.example terraform.tfvars
```

1. Paste your public key into `keys/lab-key.pub` (or change `public_key_path`).

1. Set required values in `terraform.tfvars`:

- `bastion_allowed_cidr`
- `checkpoint_admin_cidr`
- `checkpoint_gateway_sic_key`

1. Set AWS profile in `terraform.tfvars`:

- `aws_profile = "your-profile-name"`

This lab uses the AWS provider `profile` setting, so Terraform reads credentials from your local AWS CLI profile without needing to prefix every command with `AWS_PROFILE=...`.

4. Initialize and validate:

```bash
terraform init
terraform validate
```

1. Deploy:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Notes

- Default region is `eu-west-1`; override via `aws_region`.
- The Check Point module controls internal inspection-VPC subnet behavior.
- Dedicated management subnet placement in AZ1 is not exposed as an explicit input in this module version; management is deployed by the module according to its internal logic.
