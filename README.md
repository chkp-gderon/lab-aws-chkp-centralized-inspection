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

![AWS Check Point Centralized Inspection Architecture](./drawings/aws-lz-chkp-centralized-inspection.drawio.png)

To edit this diagram, open [drawings/aws-lz-chkp-centralized-inspection.drawio.png](./drawings/aws-lz-chkp-centralized-inspection.drawio.png) with [diagrams.net](https://app.diagrams.net/) (File -> Open From -> GitHub).

## Official Check Point Module

This environment uses:

- `CheckPointSW/cloudguard-network-security/aws//modules/tgw_gwlb_master` version `1.0.10`

## Quick Start

### Dev Container / Codespaces

This repository includes a dev container in [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json) with both Terraform and AWS CLI preinstalled.

If you open the repo in GitHub Codespaces and want background on the model, see [What are GitHub Codespaces?](https://docs.github.com/en/codespaces/about-codespaces/what-are-codespaces).

The dev container installs the tools, but it does not create your AWS login profiles automatically. If you want Terraform to use a dedicated AWS CLI profile named `terraform`, the minimum bootstrap below assumes you already have a working `default` AWS CLI login profile. If you do not, create one first with `aws configure sso --profile default` or your organization's standard AWS CLI login flow.

Minimum bootstrap commands:

```bash
LOGIN_SESSION=$(aws configure get login_session --profile default)
REGION=$(aws configure get region --profile default)

aws configure set login_session "$LOGIN_SESSION" --profile terraform-login
aws configure set region "${REGION:-eu-west-1}" --profile terraform-login

aws configure set credential_process "aws configure export-credentials --profile terraform-login" --profile terraform
aws configure set region "${REGION:-eu-west-1}" --profile terraform

aws login --profile terraform-login --remote
aws sts get-caller-identity --profile terraform
```

After that, keep `aws_profile = "terraform"` in `terraform.tfvars` and use Terraform normally.

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
