# Task Manager - Proxmox infrastructure

Terraform and Ansible for a small Kubernetes platform on one Proxmox server.
All VMs sit on the private bridge `vmbr1` (192.168.100.0/24).

| VM | Role |
|---|---|
| `master-1` | Kubernetes control plane (kubeadm) |
| `worker-1`, `worker-2` | Kubernetes workers |
| `runner-1` | GitHub Actions self-hosted runner that runs the Ansible deploy |
| `monitoring-1` | Prometheus, Grafana and MinIO (S3 bucket for Velero backups) |

Inside the cluster Ansible installs Flannel, MetalLB, cert-manager, Argo CD
(connected to the manifests repository) and Velero. Velero
backs up the cluster and its volumes to MinIO on `monitoring-1`, outside the
cluster, so a backup can also be restored into a new cluster.

The application source and Helm chart live in their own repositories:
`task-manager-api` (image pipeline) and `manifests` (Helm chart).

## How it runs

1. Actions → **Terraform** → Run workflow: `plan` runs, then `apply` waits for your
   approval (environment `apply`) (GitHub-hosted
   runner, state in HCP Terraform). See [terraform/README.md](terraform/README.md).
2. Register `runner-1` once, by hand (see [ansible/README.md](ansible/README.md)).
3. Actions → **Ansible** → Run workflow (runs on `runner-1`).

No kubeconfig or Kubernetes credential is stored in GitHub: `kubectl` and
`helm` run on `master-1` over SSH.

## Limits

- One master and one Proxmox server: no control-plane or host high availability.
- MongoDB (in the Helm chart) is a single replica on `local-path`; Velero
  backups protect its data, but it is not a replicated database.
- cert-manager is installed without an issuer or domain.
- MinIO is archived upstream and publishes no binaries, so Ansible builds it
  from the last official source tag and it receives no security updates.
