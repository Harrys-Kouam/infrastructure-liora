# Proxmox Kubernetes infrastructure

Terraform provisions three Kubernetes control-plane VMs and three worker VMs by
cloning a cloud-init-enabled Linux template. It uses the `bpg/proxmox` provider;
the Proxmox API token is read from `PROXMOX_VE_API_TOKEN` and is never placed in
Terraform files.

## Requirements

- Proxmox VE cluster and API token with VM, storage, and cloud-init permissions.
- Terraform 1.6 or later and the provider-supported Proxmox VE version.
- Ubuntu 24.04 cloud-init template with QEMU Guest Agent installed and enabled.
- SSH public key for the `vm_username` account.
- Free IP addresses and unused VM IDs for the six VMs, and a reachable gateway.
- Each VM in `nodes` names its Proxmox node. For host-level HA, spread the
  VMs across several physical Proxmox hosts; one host failing otherwise takes
  the whole cluster down.

## Run it from GitHub

The `Terraform` workflow validates on every push and pull request. To create the
VMs, open Actions → Terraform → Run workflow and choose `plan` (shows the changes)
or `apply` (creates the VMs). State is stored in HCP Terraform.

One-time setup:

1. In HCP Terraform (app.terraform.io), use the organization `Harrys-liora` (set in `main.tf`) and create a workspace
   named `proxmox-kubernetes` with **Execution Mode: Local**.
2. Create an HCP user or team API token.
3. Add these GitHub repository secrets:
   - `TF_API_TOKEN`: the HCP API token.
   - `PROXMOX_VE_API_TOKEN`: `user@realm!tokenname=secret`.
   - `TFVARS`: the full content of your `terraform.tfvars` (see
     `terraform.tfvars.example`).

Use `terraform output node_ips` (or the apply log) to populate `ansible/inventory.ini`.
Configure the control-plane API VIP and MetalLB's address pool in Ansible
variables only after checking that both are unused and on the correct Layer-2
network. The workflows never receive Kubernetes credentials.
