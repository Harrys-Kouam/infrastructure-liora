# Proxmox Kubernetes high-availability cluster

The playbook installs upstream Kubernetes 1.37.2 with kubeadm on exactly six Ubuntu
nodes: three control-plane nodes with stacked etcd and three workers. It also
installs containerd, Flannel networking, an HAProxy/Keepalived API VIP,
MetalLB, cert-manager, local-path storage, Prometheus/Grafana, and Argo CD.
Argo CD pulls the Task Manager Helm chart from the separate manifests repository.

GitHub Actions has no kubeconfig and does not deploy to Kubernetes. Run the
playbook from an administrator workstation with SSH access. The kubeadm join
token and certificates are kept in Ansible memory during the run, not stored
in GitHub or the repository.

## Prepare

1. Use Ubuntu 24.04 cloud-init VMs with unique hostnames/MAC addresses and
   Terraform to provision three masters and three workers.
2. Copy `inventory.ini.example` to `inventory.ini`, then replace the example
   IPs, SSH user, and key path.
3. Configure `group_vars/all.yml` with an unused API VIP, an unused MetalLB
   IP range, and the manifests repository URL.
4. Reserve the VIP and MetalLB IP range outside DHCP. Permit the Kubernetes
   API, etcd, kubelet, Flannel UDP 8472, and VRRP traffic between the nodes.
5. Install Ansible and the collection:

   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

## Deploy

The `Ansible` workflow validates on every push and pull request; its deploy job (manual trigger, runs on a
GitHub-hosted runner) runs the playbook. Add these repository secrets first
(Settings → Secrets and variables → Actions):

- `SSH_PRIVATE_KEY`: private key matching the public key given to Terraform.
- `ANSIBLE_INVENTORY`: the full content of your `inventory.ini`.
- `GRAFANA_ADMIN_PASSWORD`: at least 24 characters.
- `TASK_MANAGER_JWT_SECRET`: at least 32 characters.

The runner must reach the VMs over SSH, so the addresses in `ansible_host`
must be reachable from the internet. To run it by hand instead, export the two
passwords and run:

```bash
ansible-playbook -i ansible/inventory.ini ansible/site.yml
```

Both application passwords are passed only for that playbook run. The
kubeadm join token and control-plane certificate key are generated on the
first master and kept only in Ansible memory. `kubectl` and `helm` run on the
first master over SSH, so no kubeconfig or Kubernetes credential is ever stored
in GitHub.

Ansible installs cert-manager. Add an issuer only after choosing the DNS
provider or ingress path and configuring the real domain and account details.

If the manifests repository is private, configure a read-only Argo CD deploy
key on the cluster. Do not copy a kubeconfig or Kubernetes credentials into
GitHub Actions.

## Verify

```bash
ansible-playbook -i ansible/inventory.ini ansible/site.yml --syntax-check
ssh ubuntu@192.168.1.10 sudo kubectl get nodes -o wide
ssh ubuntu@192.168.1.10 sudo kubectl get pods --all-namespaces
```
