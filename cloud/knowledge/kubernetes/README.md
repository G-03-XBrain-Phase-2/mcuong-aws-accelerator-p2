# Kiến thức & Lý thuyết về Kubernetes (K8s)

## 1. Core Architecture (Kiến trúc lõi)
* **Control Plane vs. Worker Nodes:**
* **kube-apiserver, etcd, kube-scheduler, kube-controller-manager:**
* **kubelet, kube-proxy, Container Runtime (Docker, containerd):**

## 2. API Resources (Tài nguyên cơ bản)
* **Workloads:** Pod, Deployment, StatefulSet, DaemonSet, Job, CronJob.
* **Networking:** Service (ClusterIP, NodePort, LoadBalancer), Ingress, NetworkPolicy.
* **Config & Storage:** ConfigMap, Secret, PersistentVolume (PV), PersistentVolumeClaim (PVC), StorageClass.

## 3. Best Practices & Design Patterns
* **Probes:** Liveness, Readiness, Startup Probes.
* **Resource Management:** Requests & Limits.
* **Security:** RBAC, NetworkPolicies.
