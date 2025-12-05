# T3.micro Optimizations for EKS

## Overview
This document describes the optimizations made to run the application on EKS with t3.micro instances (1GB RAM, 2 vCPU).

## Node Configuration
- **Instance Type:** t3.micro
- **Desired Size:** 3 nodes
- **Min Size:** 2 nodes
- **Max Size:** 4 nodes

## Pod Density Limits
Each t3.micro node supports ~11 pods maximum (AWS ENI limit).
With 3 nodes = ~33 pods total capacity.

## Optimizations Applied

### 1. Application Deployment
- **Replicas:** Reduced from 2 to 1
- **HPA minReplicas:** Reduced from 2 to 1
- **HPA maxReplicas:** Reduced from 10 to 4

### 2. System Components
All system components scaled to 1 replica:
```bash
kubectl scale deployment -n kube-system aws-load-balancer-controller --replicas=1
kubectl scale deployment -n kube-system coredns --replicas=1
kubectl scale deployment -n kube-system ebs-csi-controller --replicas=1
```

### 3. Monitoring Stack
**NOT RECOMMENDED** for t3.micro due to memory constraints:
- Prometheus stack requires ~2GB RAM minimum
- Grafana requires ~512MB RAM minimum
- Total system requirements exceed t3.micro capacity

If monitoring is required, consider:
- Using t3.small (2GB RAM) or larger
- External monitoring solution (CloudWatch, Datadog, etc)
- Lightweight alternatives (metrics-server only)

### 4. Gatekeeper
**NOT RECOMMENDED** for t3.micro:
- Each Gatekeeper pod requires ~256MB RAM
- Controller + Audit = ~512MB total
- Consider using AWS native policies (IAM, Security Groups) instead

## Resource Allocation per Node

### Current State (t3.micro with 1GB RAM)
- System reserved: ~300MB
- Kubelet reserved: ~100MB
- Available for pods: ~600MB
- Overcommit ratio: Up to 400% (managed by Kubernetes)

### Recommended Pod Resources
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

## Deployment Checklist

✅ **Before Deploy:**
1. Ensure terraform.tfvars has `eks_node_desired_size = 3`
2. Verify deployment.yaml has `replicas: 1`
3. Verify hpa.yaml has `minReplicas: 1` and `maxReplicas: 4`
4. Do NOT deploy Prometheus/Grafana/Gatekeeper

✅ **After Deploy:**
1. Verify all pods are Running: `kubectl get pods -A`
2. Check node resources: `kubectl top nodes`
3. Monitor memory pressure: `kubectl describe nodes | grep -A 5 "Allocated resources"`

## Scaling Guidelines

### When to Scale Up Nodes
- If `kubectl get pods -A` shows Pending pods due to "Insufficient memory"
- If node memory usage consistently > 80%
- Consider scaling to 4 nodes before adding more workloads

### When to Scale Down
- If average node memory usage < 40% for > 30 minutes
- Minimum 2 nodes for HA

## Alternative Configurations

### Option 1: t3.small (Recommended)
- 2GB RAM per node
- Supports ~17 pods per node
- Can run lightweight monitoring
- 2 nodes sufficient for app + basic monitoring

### Option 2: Stay on EC2 + Docker Compose
- If EKS overhead is too high
- Use ALB + Target Group directly
- Lower cost, simpler operations

## Troubleshooting

### Pods Stuck in Pending
```bash
# Check why pod is pending
kubectl describe pod <pod-name> -n <namespace>

# Common causes:
# 1. "Too many pods" - Scale up nodes
# 2. "Insufficient memory" - Reduce pod limits or scale up nodes
# 3. "ImagePullBackOff" - Check ECR credentials
```

### High Memory Pressure
```bash
# Identify memory hogs
kubectl top pods -A --sort-by=memory

# Restart memory-heavy pods
kubectl rollout restart deployment <deployment-name> -n <namespace>
```

## Maintenance

### Regular Tasks
- **Weekly:** Check pod memory usage trends
- **Monthly:** Review and optimize pod resource requests/limits
- **Quarterly:** Consider upgrading to t3.small if consistently hitting limits

### Updates
When updating Kubernetes or node AMI:
1. Update one node at a time
2. Verify all pods reschedule successfully
3. Monitor for memory issues after update

## Cost Estimation

### t3.micro (Current)
- 3 nodes × $0.0104/hour = **$0.0312/hour**
- Monthly: ~$22.46 (730 hours)
- **Free Tier:** First 750 hours/month free for 12 months

### t3.small (Alternative)
- 2 nodes × $0.0208/hour = **$0.0416/hour**
- Monthly: ~$30.37 (730 hours)
- Better resource headroom

---

**Last Updated:** December 4, 2025  
**Cluster:** tx01-eks-stg  
**Kubernetes Version:** 1.32
