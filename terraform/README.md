# Proxmox Kubernetes infrastructure

Terraform provisions five VMs (1 master, 2 workers, 1 runner, 1 monitoring) by
cloning a cloud-init-enabled Linux template. It uses the `bpg/proxmox` provider;
the Proxmox API token is read from `PROXMOX_VE_API_TOKEN` and is never placed in
Terraform files.

## Requirements

- Proxmox VE cluster and API token with VM, storage, and cloud-init permissions.
- Terraform 1.6 or later and the provider-supported Proxmox VE version.
- Ubuntu 24.04 cloud-init template with QEMU Guest Agent installed and enabled.
- SSH public key for the `vm_username` account.
- Free IP addresses and unused VM IDs for the five VMs, and a reachable gateway.
- Each VM in `nodes` names its Proxmox node.

## Run it from GitHub

The `Terraform` workflow validates on every push and pull request. To create the
VMs, open Actions → Terraform → Run workflow. The `plan` job shows the changes;
the `apply` job then waits for your approval (Review deployments → Approve) and
creates the VMs. State is stored in HCP Terraform.

Create the approval gate once: Settings → Environments → New environment `apply`
→ tick **Required reviewers** and add yourself. Without it, `apply` would run
automatically.

One-time setup:

1. In HCP Terraform (app.terraform.io), use the organization `Harrys-liora` (set in `main.tf`) and create a workspace
   named `proxmox-kubernetes` with **Execution Mode: Local**.
2. Create an HCP user or team API token.
3. Add these GitHub repository secrets:
   - `TF_API_TOKEN`: the HCP API token.
   - `PROXMOX_VE_API_TOKEN`: `user@realm!tokenname=secret`.

The values (Proxmox address, node, network, VM list) are the defaults in
`variables.tf`; edit them there. None of them is a secret.

Use the apply log (`node_ips` output) to fill `ansible/inventory.ini`.
