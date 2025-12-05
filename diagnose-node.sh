#!/bin/bash
echo "=== KUBELET STATUS ==="
systemctl status kubelet --no-pager
echo ""
echo "=== KUBELET LOGS (last 50 lines) ==="
journalctl -u kubelet -n 50 --no-pager
echo ""
echo "=== CONTAINERD STATUS ==="
systemctl status containerd --no-pager
echo ""
echo "=== NETWORK CONNECTIVITY ==="
curl -k https://D786C9A86D020997D814FE7A3F99BFCF.gr7.us-east-1.eks.amazonaws.com/healthz || echo "Cannot reach control plane"
echo ""
echo "=== AWS IAM ROLE ==="
curl -s http://169.254.169.254/latest/meta-data/iam/info | jq .
