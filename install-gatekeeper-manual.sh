# Manual Gatekeeper Installation (alternative to Helm)

# Install Gatekeeper via kubectl
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.15.0/deploy/gatekeeper.yaml

# Wait for pods
kubectl wait --for=condition=Available deployment/gatekeeper-controller-manager -n gatekeeper-system --timeout=300s
kubectl wait --for=condition=Available deployment/gatekeeper-audit -n gatekeeper-system --timeout=300s

# Check status
kubectl get pods -n gatekeeper-system

# Apply templates
kubectl apply -f k8s/policies/templates/

# Apply constraints (dryrun)
kubectl apply -f k8s/policies/constraints/dryrun/

# Create ServiceMonitor for Prometheus
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: gatekeeper-controller-manager-metrics
  namespace: gatekeeper-system
  labels:
    app: gatekeeper
    release: kube-prometheus-stack
spec:
  ports:
  - name: metrics
    port: 8888
    protocol: TCP
    targetPort: 8888
  selector:
    control-plane: controller-manager
    gatekeeper.sh/operation: webhook
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: gatekeeper-controller-manager
  namespace: gatekeeper-system
  labels:
    app: gatekeeper
    release: kube-prometheus-stack
spec:
  selector:
    matchLabels:
      app: gatekeeper
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
EOF

echo "✅ Gatekeeper installed manually!"
