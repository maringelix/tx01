# 🗄️ Configuração do Banco de Dados

## 📋 Visão Geral

O ambiente tx01 utiliza **Amazon RDS PostgreSQL 17.6** como banco de dados.

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                    │
│                                                         │
│  ┌──────────────┐         ┌─────────────────────┐     │
│  │ EKS Pods     │────────▶│  RDS PostgreSQL     │     │
│  │ (Private SN) │  5432   │  (Private Subnet)   │     │
│  │              │         │  tx01-db-stg        │     │
│  └──────────────┘         └─────────────────────┘     │
│       │                                                │
│       │                                                │
│  ┌────▼────────┐          ┌─────────────────────┐     │
│  │ EC2         │─────────▶│  Security Groups    │     │
│  │ Instances   │  5432    │  - RDS SG           │     │
│  │ (Private)   │          │  - EKS Cluster SG   │     │
│  └─────────────┘          │  - EC2 SG           │     │
│                           └─────────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Groups

### RDS Security Group (`tx01-rds-sg-stg`)

**Regras de Entrada (Ingress):**

| Protocolo | Porta | Origem                    | Descrição                      |
|-----------|-------|---------------------------|--------------------------------|
| TCP       | 5432  | `sg-03b2d3b3665380013`    | PostgreSQL from EC2 instances  |
| TCP       | 5432  | `sg-0e76500741915a934`    | PostgreSQL from EKS cluster    |

**Terraform:**
```hcl
# terraform/modules/rds.tf

# Security Group Rule for EKS to RDS access
resource "aws_security_group_rule" "rds_from_eks" {
  count                    = var.enable_eks ? 1 : 0
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id
  description              = "PostgreSQL from EKS cluster"
}
```

---

## 🔑 Credenciais

As credenciais do banco são armazenadas no **AWS Secrets Manager** e injetadas nos pods via Kubernetes Secrets.

### Secrets Manager

**Nome:** `tx01-db-credentials-stg-v2`

**Estrutura:**
```json
{
  "username": "dbadmin",
  "password": "WOf[Hm9fkTU<Mg0AF_W610-DRIAwb[:{",
  "engine": "postgres",
  "host": "tx01-db-stg.ckfsky20e9xj.us-east-1.rds.amazonaws.com",
  "port": 5432,
  "dbname": "tx01_stg"
}
```

### Kubernetes Secret

**Nome:** `tx01-db-credentials`

**Criação automática via workflow:**
```yaml
- name: Create Database Secret
  run: |
    DB_SECRET=$(aws secretsmanager get-secret-value --secret-id tx01-db-credentials-stg-v2 --query SecretString --output text)
    kubectl create secret generic tx01-db-credentials \
      --from-literal=host=$(echo $DB_SECRET | jq -r '.host') \
      --from-literal=port=$(echo $DB_SECRET | jq -r '.port') \
      --from-literal=dbname=$(echo $DB_SECRET | jq -r '.dbname') \
      --from-literal=username=$(echo $DB_SECRET | jq -r '.username') \
      --from-literal=password=$(echo $DB_SECRET | jq -r '.password') \
      --dry-run=client -o yaml | kubectl apply -f -
```

---

## 🔧 Variáveis de Ambiente (Aplicação)

A aplicação dx01 utiliza as seguintes variáveis de ambiente:

| Variável       | Origem                              | Exemplo                                         |
|----------------|-------------------------------------|-------------------------------------------------|
| `DB_HOST`      | `tx01-db-credentials` (secret)      | tx01-db-stg.ckfsky20e9xj.us-east-1.rds.amazon... |
| `DB_PORT`      | `tx01-db-credentials` (secret)      | 5432                                            |
| `DB_NAME`      | `tx01-db-credentials` (secret)      | tx01_stg                                        |
| `DB_USER`      | `tx01-db-credentials` (secret)      | dbadmin                                         |
| `DB_PASSWORD`  | `tx01-db-credentials` (secret)      | WOf[Hm9fkTU<Mg0AF_W610-DRIAwb[:{              |

**Deployment configuration:**
```yaml
# k8s/deployment.yaml
env:
  - name: DB_HOST
    valueFrom:
      secretKeyRef:
        name: tx01-db-credentials
        key: host
  - name: DB_PORT
    valueFrom:
      secretKeyRef:
        name: tx01-db-credentials
        key: port
  # ... etc
```

---

## 🗃️ Schema do Banco

### Tabelas

**1. visits** - Registro de acessos
```sql
CREATE TABLE visits (
  id SERIAL PRIMARY KEY,
  ip_address VARCHAR(45),
  user_agent TEXT,
  path VARCHAR(255),
  visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_visits_visited_at ON visits(visited_at DESC);
```

**2. app_users** - Usuários da aplicação
```sql
CREATE TABLE app_users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_created_at ON app_users(created_at DESC);
```

---

## 🧪 Testes

### Health Check
```bash
curl http://k8s-default-tx01ingr-376d89270a-857461048.us-east-1.elb.amazonaws.com/api/health
```

**Resposta esperada:**
```json
{
  "status": "healthy",
  "message": "API está funcionando! 🚀",
  "timestamp": "2025-12-04T13:26:42.449Z",
  "uptime": 122.93,
  "database": {
    "connected": true,
    "timestamp": "2025-12-04T13:26:42.439Z",
    "version": "PostgreSQL 17.6",
    "poolSize": 1,
    "idleConnections": 1,
    "waitingRequests": 0
  },
  "stats": {
    "totalVisits": 0,
    "totalUsers": 0,
    "visitsLast24h": 0
  }
}
```

### Verificar Conexão nos Pods
```bash
kubectl logs deployment/tx01-app --tail=20 | grep -i database
```

**Output esperado:**
```
info: 🔄 Attempting to connect to database...
{"level":"info","message":"✅ Database connection established"}
{"level":"info","message":"Initializing database schema..."}
{"level":"info","message":"✅ Database schema initialized successfully"}
info: ✅ Database initialized successfully
```

---

## 🔄 Troubleshooting

### Problema: Connection Timeout

**Sintoma:**
```
error: ❌ Failed to initialize database 
{"error":"Connection terminated due to connection timeout"}
```

**Causa:** Security Group do RDS não permite acesso do EKS.

**Solução:**
```bash
# 1. Verificar regras do RDS SG
aws ec2 describe-security-groups --group-ids sg-0fd4e45e57e183e16

# 2. Adicionar regra para EKS (se necessário)
aws ec2 authorize-security-group-ingress \
  --group-id sg-0fd4e45e57e183e16 \
  --protocol tcp --port 5432 \
  --source-group sg-0e76500741915a934

# 3. Reiniciar pods
kubectl rollout restart deployment/tx01-app
```

### Problema: Credenciais Incorretas

**Sintoma:**
```
error: password authentication failed for user "dbadmin"
```

**Solução:**
```bash
# 1. Verificar secret no Kubernetes
kubectl get secret tx01-db-credentials -o jsonpath='{.data.password}' | base64 -d

# 2. Verificar secret no Secrets Manager
aws secretsmanager get-secret-value --secret-id tx01-db-credentials-stg-v2

# 3. Recriar secret no Kubernetes
kubectl delete secret tx01-db-credentials
# Executar workflow eks-deploy.yml (action: deploy)
```

---

## 📚 Referências

- **RDS Instance:** tx01-db-stg
- **Endpoint:** tx01-db-stg.ckfsky20e9xj.us-east-1.rds.amazonaws.com:5432
- **Engine:** PostgreSQL 17.6
- **Storage:** 20GB gp3
- **Instance Class:** db.t4g.micro (ARM)
- **Backup Retention:** 1 dia (staging)
- **Multi-AZ:** Desabilitado (staging)
- **Encryption:** Habilitada (at-rest)

---

## ✅ Checklist de Deploy

Antes de fazer deploy da aplicação:

- [ ] RDS está no status `available`
- [ ] Secret `tx01-db-credentials-stg-v2` existe no Secrets Manager
- [ ] Security Group permite acesso do EKS (regra adicionada via Terraform)
- [ ] Kubernetes Secret `tx01-db-credentials` foi criado
- [ ] Deployment tem as variáveis de ambiente configuradas
- [ ] Health check da API retorna `database.connected: true`

---

**Última Atualização:** 2025-12-04  
**Versão PostgreSQL:** 17.6  
**Commit:** ed59ad2
