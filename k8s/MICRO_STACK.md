# 📊 Micro Stack vs Full Stack Comparison

## 🎯 Overview

This project supports **two deployment modes** for Observability and Gatekeeper:

1. **MICRO Stack** - Optimized for AWS Free Tier (t3.micro nodes)
2. **FULL Stack** - Complete feature set (requires t3.small+ nodes)

---

## 🆓 Free Tier Considerations

### **AWS Free Tier Limits:**
- ✅ **750 hours/month** of t3.micro (enough for ~6 instances 24/7)
- ✅ **5GB CloudWatch Logs** (free)
- ✅ **30GB EBS gp2** (free)
- ❌ **t3.small/medium NOT free** (~$15-30/month per instance)

### **EKS Pod Density:**
- `t3.micro`: **4 pods/node** (AWS ENI limitation)
- `t3.small`: **11 pods/node**
- `t3.medium`: **17 pods/node**
- `t3.large`: **35 pods/node**

---

## 📊 Observability Stack Comparison

### **MICRO Stack** (deploy-observability-micro.yml)

| Component | Status | Pods | Memory | Storage |
|-----------|--------|------|--------|---------|
| **Prometheus** | ✅ Enabled | 1 | 256-512MB | 2Gi |
| **Grafana** | ✅ Enabled | 1 | 100-200MB | 2Gi |
| **Kube State Metrics** | ✅ Enabled | 1 | 64-128MB | - |
| **AlertManager** | ❌ Disabled | 0 | - | - |
| **Node Exporter** | ❌ Disabled | 0 | - | - |
| **Loki** | ❌ Disabled | 0 | - | - |
| **Promtail** | ❌ Disabled | 0 | - | - |
| **TOTAL** | - | **3** | **~530MB** | **4Gi** |

**Retention:** 3 days (vs 7 days full)  
**Cost:** $0/month (Free Tier)

---

### **FULL Stack** (deploy-observability.yml)

| Component | Status | Pods | Memory | Storage |
|-----------|--------|------|--------|---------|
| **Prometheus** | ✅ Enabled | 1 | 500MB | 10Gi |
| **Grafana** | ✅ Enabled | 1 | 200MB | 5Gi |
| **Kube State Metrics** | ✅ Enabled | 1 | 100MB | - |
| **AlertManager** | ✅ Enabled | 1 | 100MB | - |
| **Node Exporter** | ✅ Enabled | 4 (DS) | 50MB/node | - |
| **Loki** | ✅ Enabled | 1 | 300MB | 10Gi |
| **Promtail** | ✅ Enabled | 4 (DS) | 50MB/node | - |
| **TOTAL** | - | **~14** | **~1.7GB** | **25Gi** |

**Retention:** 7 days  
**Cost:** ~$75-100/month (requires t3.small nodes)

---

## 🛡️ Gatekeeper Comparison

### **MICRO Stack** (deploy-gatekeeper-micro.yml)

| Component | Status | Pods | Memory | Features |
|-----------|--------|------|--------|----------|
| **Controller Manager** | ✅ Enabled | 1 | 80-150MB | Admission control |
| **Audit** | ❌ Disabled | 0 | - | - |
| **TOTAL** | - | **1** | **~150MB** | Admission only |

**Capabilities:**
- ✅ Block/log violations on create/update
- ❌ No periodic audit of existing resources
- ✅ Metrics available in Prometheus

**Cost:** $0/month (Free Tier)

---

### **FULL Stack** (deploy-gatekeeper.yml)

| Component | Status | Pods | Memory | Features |
|-----------|--------|------|--------|----------|
| **Controller Manager** | ✅ Enabled | 1 | 256MB | Admission control |
| **Audit** | ✅ Enabled | 1 | 256MB | Retroactive checks |
| **TOTAL** | - | **2** | **~512MB** | Full compliance |

**Capabilities:**
- ✅ Block/log violations on create/update
- ✅ Periodic audit every 60s
- ✅ Retroactive policy enforcement
- ✅ Full metrics and reporting

**Cost:** ~$25-50/month (requires t3.small nodes)

---

## 🎯 Workflow Selection Guide

### **Use MICRO Workflows When:**
- ✅ Running on **t3.micro** nodes (Free Tier)
- ✅ **Limited budget** (<$100/month)
- ✅ **Learning/Testing** environment
- ✅ **Small workloads** (<5 services)
- ✅ Can use **CloudWatch Logs** for logging

### **Use FULL Workflows When:**
- ✅ Running on **t3.small+** nodes
- ✅ **Production** environment
- ✅ Need **advanced alerting** (AlertManager)
- ✅ Need **centralized logging** (Loki)
- ✅ Need **retroactive compliance** (Gatekeeper Audit)
- ✅ **Medium/Large workloads** (>10 services)

---

## 📋 Deployment Instructions

### **MICRO Stack (Free Tier)**

#### **1. Scale to 6 nodes:**
```bash
# Update terraform/stg/terraform.tfvars
eks_node_desired_size = 6
eks_node_min_size = 4
eks_node_max_size = 6

# Apply via GitHub Actions: eks-deploy.yml → provision
```

#### **2. Deploy Observability MICRO:**
```bash
# GitHub Actions: deploy-observability-micro.yml
Environment: stg
Action: install
```

#### **3. Deploy Gatekeeper MICRO (optional):**
```bash
# GitHub Actions: deploy-gatekeeper-micro.yml
Environment: stg
Action: install
Enforcement Mode: dryrun
```

#### **4. Access Grafana:**
```bash
kubectl get svc -n monitoring kube-prometheus-stack-grafana
# Use LoadBalancer DNS with user: admin, password: (from secret)
```

---

### **FULL Stack (Production)**

#### **1. Upgrade to t3.small:**
```bash
# Update terraform/stg/terraform.tfvars
eks_node_instance_type = "t3.small"
eks_node_desired_size = 3
eks_node_min_size = 2
eks_node_max_size = 4

# Apply via GitHub Actions: eks-deploy.yml → provision
```

#### **2. Deploy Observability FULL:**
```bash
# GitHub Actions: deploy-observability.yml
Environment: stg
Action: install
Install Gatekeeper: false (optional)
```

#### **3. Deploy Gatekeeper FULL (optional):**
```bash
# GitHub Actions: deploy-gatekeeper.yml
Environment: stg
Action: install
Enforcement Mode: dryrun (then switch to enforce)
```

---

## 💰 Cost Comparison

### **Current Setup (MICRO + 6 nodes t3.micro)**
```
EKS Control Plane:  $73.00/month
6x t3.micro nodes:  $0.00/month (Free Tier)
RDS db.t3.micro:    $15.00/month
EBS volumes (4Gi):  $0.40/month
CloudWatch Logs:    $0.00/month (5GB free)
────────────────────────────────
TOTAL:              ~$88/month
```

**Pod Capacity:** 24 slots  
**Used:** ~20 pods (System + App + Observability + Gatekeeper)  
**Free:** 4 pods

---

### **Future Setup (FULL + 3 nodes t3.small)**
```
EKS Control Plane:  $73.00/month
3x t3.small nodes:  $45.00/month ($15 each)
RDS db.t3.micro:    $15.00/month
EBS volumes (25Gi): $2.50/month
CloudWatch Logs:    $0.00/month (5GB free)
────────────────────────────────
TOTAL:              ~$135/month
```

**Pod Capacity:** 33 slots (3 × 11)  
**Used:** ~30 pods (Full stack)  
**Free:** 3 pods

**Increase:** +$47/month for full features

---

## 🔄 Migration Path

### **From MICRO to FULL:**

1. **Uninstall MICRO stacks:**
   ```bash
   # Observability
   GitHub Actions: deploy-observability-micro.yml → uninstall
   
   # Gatekeeper
   GitHub Actions: deploy-gatekeeper-micro.yml → uninstall
   ```

2. **Upgrade instance type:**
   ```bash
   # terraform/stg/terraform.tfvars
   eks_node_instance_type = "t3.small"
   eks_node_desired_size = 3
   
   # Apply: eks-deploy.yml → provision
   ```

3. **Install FULL stacks:**
   ```bash
   # Observability
   GitHub Actions: deploy-observability.yml → install
   
   # Gatekeeper
   GitHub Actions: deploy-gatekeeper.yml → install
   ```

---

## 📊 Features Matrix

| Feature | MICRO | FULL |
|---------|-------|------|
| **Prometheus Metrics** | ✅ 3 days | ✅ 7 days |
| **Grafana Dashboards** | ✅ | ✅ |
| **Kube State Metrics** | ✅ | ✅ |
| **AlertManager** | ❌ | ✅ |
| **Node Metrics** | ⚠️ Basic | ✅ Detailed |
| **Centralized Logs** | ❌ (use CW) | ✅ Loki |
| **Gatekeeper Admission** | ✅ | ✅ |
| **Gatekeeper Audit** | ❌ | ✅ |
| **Policy Violations** | ⚠️ On admission | ✅ Continuous |
| **Resource Usage** | ~680MB | ~2.2GB |
| **Pod Slots** | 4 pods | ~16 pods |
| **Cost** | $0 extra | +$47/month |

---

## 🎓 Recommendations

### **For Learning/Development:**
✅ Use **MICRO stack** on **6x t3.micro**  
✅ Free Tier eligible  
✅ All essential features available  
✅ Perfect for learning Kubernetes, Prometheus, Grafana

### **For Production (Small):**
⚠️ Start with **MICRO**, monitor closely  
⚠️ Add CloudWatch Alarms for critical alerts  
⚠️ Use CloudWatch Logs for application logs  
⚠️ Plan upgrade path to FULL when budget allows

### **For Production (Medium/Large):**
✅ Use **FULL stack** on **3x t3.small+**  
✅ Complete observability and policy enforcement  
✅ AlertManager for complex alerting  
✅ Loki for centralized logging  
✅ Gatekeeper Audit for compliance

---

## 📝 Maintenance

### **MICRO Stack:**
- Check Grafana dashboards weekly
- Review policy violations in logs
- Monitor CloudWatch Logs for application issues
- Prometheus metrics retained 3 days

### **FULL Stack:**
- AlertManager sends proactive alerts
- Loki provides centralized log search
- Gatekeeper Audit runs every 60s
- Prometheus metrics retained 7 days

---

## 🔗 Useful Links

- [AWS Free Tier](https://aws.amazon.com/free/)
- [EKS Pod Networking](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html)
- [Prometheus Operator](https://github.com/prometheus-operator/kube-prometheus)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

---

## ✅ Summary

**MICRO Stack = 4 pods, ~$0/month extra, 80% features**  
**FULL Stack = 16 pods, ~$47/month extra, 100% features**

**Choose MICRO for learning/testing on Free Tier.**  
**Upgrade to FULL when ready for production scale.**
