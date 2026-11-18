# Ansible

`site.yml` checks the inventory and secrets, then runs `kubernetes.yml` (the
cluster) and `monitoring.yml` (the monitoring VM). Together they install upstream Kubernetes 1.37 with kubeadm (containerd, Flannel)
on one master and two workers, MinIO + Prometheus + Grafana on the monitoring
VM, and MetalLB, cert-manager, local-path storage, Velero and Argo CD in the
cluster. The runner VM is not in the inventory. Node hostnames and the absence of swap
come from the Ubuntu cloud image and cloud-init. MinIO starts after the cluster,
so Velero's storage location turns `Available` about a minute after the run.

Prometheus on `monitoring-1` scrapes `node_exporter` on every VM (CPU, memory,
disk, network); import Grafana dashboard 1860 to view it. Kubernetes objects
are not scraped.

## One-time setup

1. Provision the VMs with Terraform.
2. `inventory.ini` lists the VMs with the same IPs as `terraform/variables.tf`
   (keep both in sync). In `group_vars/all.yml`, `metallb_addresses` must be
   unused private IPs.
3. Register the runner on `runner-1`. From a machine that can reach the
   Proxmox host:

   ```bash
   ssh -J root@<proxmox-ip> ubuntu@192.168.100.30
   sudo apt-get update && sudo apt-get install -y python3-venv git
   ```

   Then follow GitHub → repository → Settings → Actions → Runners → New
   self-hosted runner (Linux x64), adding the label `proxmox`, and install it
   as a service (`sudo ./svc.sh install && sudo ./svc.sh start`).
4. Add these repository secrets (Settings → Secrets and variables → Actions):

   | Secret | Value |
   |---|---|
   | `SSH_PRIVATE_KEY` | private key matching the public key given to Terraform |
   | `GRAFANA_ADMIN_PASSWORD` | 24+ characters, from `openssl rand -base64 24` |
   | `TASK_MANAGER_JWT_SECRET` | 32+ characters, from `openssl rand -hex 32` |
   | `MINIO_ROOT_PASSWORD` | 24+ characters, from `openssl rand -base64 24` |

## Deploy

Actions → **Ansible** → Run workflow. Only that deploy job runs on the
self-hosted runner and only on a manual trigger. The repository is public, so
keep "Require approval for all outside collaborators" enabled.

Grafana's admin password is applied the first time Grafana starts; change it
later with `grafana cli admin reset-admin-password`. Use a base64 password.

## Verify

```bash
ssh -J root@<proxmox-ip> ubuntu@192.168.100.13 sudo kubectl get nodes
ssh -J root@<proxmox-ip> ubuntu@192.168.100.13 sudo kubectl get pods -A
ssh -J root@<proxmox-ip> ubuntu@192.168.100.13 sudo kubectl get backupstoragelocation -n velero
```

The VMs are private. To open Grafana (`http://192.168.100.40:3000`), Prometheus
(`:9090`), Argo CD or the application (MetalLB addresses) from your computer,
use an SSH tunnel through the Proxmox host, for example
`ssh -L 3000:192.168.100.40:3000 root@<proxmox-ip>`.

The Velero server runs in the cluster; the `velero` client is installed on
`master-1`. Back up with `sudo velero backup create demo --include-namespaces task-manager`
(use `--kubeconfig /etc/kubernetes/admin.conf` if needed) and restore with
`velero restore create --from-backup demo`.

cert-manager has no issuer; add one only once you have a real domain.
If the manifests repository becomes private, configure an Argo CD deploy key.
