# Task Manager - Proxmox infrastructure

This repository owns Terraform and Ansible only. It provisions the existing
Task Manager project's Proxmox VMs and configures a six-node Kubernetes cluster:

- 3 kubeadm control-plane nodes with stacked etcd quorum
- 3 Kubernetes worker nodes for application workloads
- HAProxy + Keepalived virtual IP for the Kubernetes API
- MetalLB for `LoadBalancer` Services
- cert-manager, Prometheus/Grafana, and Argo CD

The application source and Helm chart remain in their own repositories:

- Application: `task-manager-api`
- Helm chart and Argo CD configuration: `manifests`

## Provision and configure

1. Prepare a cloud-init Linux template on Proxmox with QEMU Guest Agent.
2. Copy `terraform/terraform.tfvars.example` to
   `terraform/terraform.tfvars`, then replace every example value.
3. Export a least-privilege Proxmox API token as `PROXMOX_VE_API_TOKEN` and
   review `terraform plan` before applying.
4. Copy `ansible/inventory.ini.example` to `ansible/inventory.ini`, set the SSH
   key and actual node addresses, then configure `ansible/group_vars/all.yml`.
5. Install the Ansible collection and run `ansible/site.yml` from this
   repository. Set `GRAFANA_ADMIN_PASSWORD` in the local environment first.

The GitHub workflows run Terraform validation, Ansible syntax checks, and
ansible-lint. They do not apply infrastructure or connect to Kubernetes.
Argo CD performs application delivery by polling the manifests repository;
GitHub Actions receives no kubeconfig or Kubernetes credentials.

## Production requirements and caveats

- Spread the three master VMs across separate physical Proxmox hosts. Six VMs
  on one hypervisor do not provide host-level high availability.
- Reserve the control-plane VIP and MetalLB pool outside DHCP, and verify that
  VRRP and Layer-2 advertisements are permitted on the node VLAN.
- The existing Helm chart still runs MongoDB as a single StatefulSet replica
  on `local-path`. The Kubernetes control plane and API are HA, but MongoDB
  data is not. Use a replicated MongoDB deployment or an external HA database
  before treating application data as production-available.
- `cert-manager` is installed by Ansible. Configure an issuer and a real DNS
  name before enabling public certificate issuance.
