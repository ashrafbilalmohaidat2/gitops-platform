# DevOps (GitOps Platform)

A self-hosted, production-style Kubernetes platform built on **K3s**, provisioned with **Terraform**, and managed through **GitOps**. This project documents the journey of building an Internal Developer Platform (IDP) from scratch — including infrastructure, GitOps, observability, and security layers.

---

## 📌 Project Goal

Build a general-purpose Kubernetes platform (not tied to a single application) that demonstrates the full DevOps lifecycle:

**Infrastructure (IaC) → GitOps Delivery → Observability → Security (Policy as Code)**

---

## 🏗️ Infrastructure Overview

| Component | Choice |
|---|---|
| Cloud Provider | AWS |
| Compute | EC2 `m7i-flex.large` (2 vCPU / 8 GB RAM) |
| OS | Ubuntu |
| Kubernetes Distribution | K3s (single-node cluster) |
| Access | kubectl from local machine via K3s API (port 6443) |

---

## ✅ Sprint 1: Infrastructure Foundation

**Goal:** Have a working K3s cluster, accessible remotely via `kubectl` from a local machine.

### 1. Environment Setup

- Provisioned an AWS EC2 instance (`m7i-flex.large`, Ubuntu).
- Configured the EC2 Security Group to allow:
  - **SSH (22)** — restricted to my IP
  - **Kubernetes API (6443)** — restricted to my IP
  - **HTTP/HTTPS (80/443)** — for future Ingress use

### 2. Installing K3s

Connected to the instance via SSH and installed K3s using the official install script:

```bash
curl -sfL https://get.k3s.io | sh -
```

Verified the installation:

```bash
sudo systemctl status k3s
sudo k3s kubectl get nodes
```

### 3. Remote Access Configuration (kubeconfig)

By default, the K3s kubeconfig file (`/etc/rancher/k3s/k3s.yaml`) is owned by `root` and cannot be copied directly via `scp` due to permission restrictions.

**Fix applied:**
1. Created a temporary readable copy of the kubeconfig on the server:
   ```bash
   sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/k3s.yaml
   sudo chown ubuntu:ubuntu /home/ubuntu/k3s.yaml
   ```
2. Copied it to the local machine via `scp`.
3. **Deleted the temporary copy from the server** immediately after transfer, since the kubeconfig grants full admin access to the cluster and should never persist in an insecure location.

### 4. TLS Certificate Issue (Public IP)

**Problem:** After copying the kubeconfig and pointing it to the EC2 public IP, `kubectl` failed with:

```
tls: failed to verify certificate: x509: certificate is valid for 10.43.0.1, 127.0.0.1, 172.31.32.181, ::1, not <public-ip>
```

**Root cause:** K3s generates its TLS certificate automatically based on IPs it knows about at install time (internal/private IPs). It has no way of knowing in advance which public IP will be used to access it, so the public IP is not included as a valid Subject Alternative Name (SAN).

**Fix applied:**
1. Created a K3s config file on the server:
   ```bash
   sudo nano /etc/rancher/k3s/config.yaml
   ```
   With the following content:
   ```yaml
   tls-san:
     - "<EC2-PUBLIC-IP>"
   ```
2. Restarted K3s to regenerate the certificate with the public IP included:
   ```bash
   sudo systemctl restart k3s
   ```
3. Re-copied the updated kubeconfig (same secure copy → delete process as above).

### 5. Verification

```bash
export KUBECONFIG=~/.kube/config-k3s
kubectl get nodes
```

**Result:**
```
NAME               STATUS   ROLES           AGE     VERSION
ip-172-31-32-181   Ready    control-plane   8m43s   v1.36.2+k3s1
```

The cluster is reachable and manageable from the local machine.

---

## 🔐 Security Notes

- The kubeconfig file grants full admin access to the cluster and is treated like a root credential.
- It is **never committed to Git** (excluded via `.gitignore`).
- EC2 Security Group access is restricted by IP rather than open to `0.0.0.0/0`.

---

## 📂 Repository Structure (so far)

```
devops-platform/
├── terraform/
│   ├── providers.tf
│   ├── namespaces.tf
│   └── kubeconfig        # gitignored, never committed
└── README.md
```

---

## 🚀 Next Steps (Sprint 2)

- Manage cluster resources (namespaces) declaratively via Terraform using the Kubernetes provider.
- Prepare namespace structure for upcoming layers: `platform`, `apps`, `monitoring`, `security`, `argocd`.