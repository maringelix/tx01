# OPA Gatekeeper Policies

Kubernetes admission control policies for the EKS cluster.

## Policies

| Policy | Mode | Description |
|--------|------|-------------|
| Required Labels | dryrun | Ensures `app` label on all resources |
| Block Privileged | deny | Blocks privileged containers |
| Resource Limits | dryrun | Requires CPU/memory requests and limits |

## Deployment

Policies are deployed via the `deploy-gatekeeper` workflow (`workflow_dispatch`).

## Verification

```bash
kubectl get constraints
kubectl get constrainttemplate
```
