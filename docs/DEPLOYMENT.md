# CineFlow AI - Deployment Guide

## Overview

This guide covers deploying CineFlow AI to different environments:
- Development (local machine)
- Staging (AWS EKS)
- Production (AWS EKS multi-region)

## Prerequisites

### Required Tools

- **kubectl** >= 1.27
- **helm** >= 3.10
- **terraform** >= 1.6.0
- **aws-cli** >= 2.13
- **docker** >= 24.0
- **git** >= 2.40

### AWS Account Setup

```bash
# Configure AWS credentials
aws configure

# Create S3 bucket for Terraform state
aws s3 mb s3://cineflow-terraform-state --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket cineflow-terraform-state \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for Terraform locks
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-west-2
```

## Local Development

### Quick Start

```bash
# Clone repository
git clone https://github.com/ChaitanyaJoshi1769/CineFlowAI.git
cd CineFlowAI

# Copy environment template
cp .env.example .env

# Edit configuration
nano .env

# Install all dependencies
./scripts/setup/install-all.sh

# Start backend services
./scripts/setup/start-backend.sh

# In another terminal, start frontend
cd frontend
npm run dev
```

Visit `http://localhost:3000`

### Docker Compose Services

```bash
# Start all services
docker-compose -f backend/docker-compose.yml up -d

# View service logs
docker-compose -f backend/docker-compose.yml logs -f

# Stop all services
docker-compose -f backend/docker-compose.yml down

# Remove volumes (caution: deletes data)
docker-compose -f backend/docker-compose.yml down -v
```

**Services:**
- PostgreSQL (5432)
- Redis (6379)
- Neo4j (7687, 7474)
- Qdrant (6333, 6334)
- Elasticsearch (9200)
- Kafka (9092)
- Prometheus (9090)
- Grafana (3001)
- Jaeger (16686)
- Temporal (7233, 8080)
- NATS (4222)
- MinIO (9000, 9001)
- LocalStack (4566)

## Staging Deployment

### Infrastructure Setup

```bash
# Navigate to infrastructure directory
cd infrastructure/terraform

# Initialize Terraform
terraform init \
    -backend-config="bucket=cineflow-terraform-state" \
    -backend-config="key=staging/terraform.tfstate" \
    -backend-config="region=us-west-2"

# Plan deployment
terraform plan \
    -var="environment=staging" \
    -out=staging.tfplan

# Apply configuration
terraform apply staging.tfplan
```

### Retrieve Cluster Information

```bash
# Get cluster endpoint
aws eks describe-cluster \
    --name cineflow-staging \
    --query 'cluster.endpoint' \
    --region us-west-2

# Update kubeconfig
aws eks update-kubeconfig \
    --name cineflow-staging \
    --region us-west-2

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Deploy with Helm

```bash
# Add Helm repository (once available)
helm repo add cineflow https://charts.cineflow.ai
helm repo update

# Create namespace
kubectl create namespace cineflow

# Create secrets
kubectl create secret generic database-credentials \
    --from-literal=connection-string="$(terraform output -raw database_connection_string)" \
    -n cineflow

kubectl create secret generic jwt-secrets \
    --from-literal=secret="$(openssl rand -base64 32)" \
    -n cineflow

# Deploy with Helm
helm install cineflow cineflow/cineflow \
    --namespace cineflow \
    --values infrastructure/helm/values-staging.yaml \
    --wait \
    --timeout 10m

# Verify deployment
kubectl get pods -n cineflow
kubectl get svc -n cineflow
```

### Configuration Updates

```bash
# Update deployment
helm upgrade cineflow cineflow/cineflow \
    --namespace cineflow \
    --values infrastructure/helm/values-staging.yaml \
    --wait

# Rollback if needed
helm rollback cineflow -n cineflow

# Check status
helm status cineflow -n cineflow
```

### Monitoring

```bash
# Port forward Grafana
kubectl port-forward -n cineflow svc/grafana 3000:80

# Port forward Prometheus
kubectl port-forward -n cineflow svc/prometheus 9090:9090

# View logs
kubectl logs -n cineflow -f deployment/api-gateway
kubectl logs -n cineflow -f deployment/narrative-planner
```

## Production Deployment

### Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Database backups created
- [ ] Monitoring dashboards verified
- [ ] Incident response plan in place
- [ ] Staging deployment validated
- [ ] Security scanning completed
- [ ] Performance baselines established

### Infrastructure Setup

```bash
# Initialize Terraform for production
cd infrastructure/terraform

terraform init \
    -backend-config="bucket=cineflow-terraform-state" \
    -backend-config="key=prod/terraform.tfstate" \
    -backend-config="region=us-west-2"

# Create plan with production settings
terraform plan \
    -var="environment=production" \
    -var="node_group_desired_size=10" \
    -var="gpu_desired_size=5" \
    -out=prod.tfplan

# Apply with caution - this creates production infrastructure
terraform apply prod.tfplan
```

### Database Backups

```bash
# Create RDS snapshot before deployment
aws rds create-db-snapshot \
    --db-instance-identifier cineflow-prod \
    --db-snapshot-identifier "cineflow-prod-backup-$(date +%Y%m%d-%H%M%S)"

# Verify backup
aws rds describe-db-snapshots \
    --query 'DBSnapshots[?contains(DBSnapshotIdentifier, `cineflow-prod`)]'
```

### Deploy to Production

```bash
# Update kubeconfig
aws eks update-kubeconfig \
    --name cineflow-production \
    --region us-west-2

# Create namespace
kubectl create namespace cineflow

# Create secrets from AWS Secrets Manager
# Configure RBAC
kubectl apply -f infrastructure/k8s/01-namespace.yaml

# Create secrets
aws secretsmanager get-secret-value \
    --secret-id cineflow-db-credentials \
    --query SecretString | \
    kubectl create secret generic database-credentials \
    --from-file=/dev/stdin -n cineflow

# Deploy with Helm
helm install cineflow cineflow/cineflow \
    --namespace cineflow \
    --values infrastructure/helm/values-production.yaml \
    --wait \
    --timeout 15m

# Verify all pods are running
kubectl get pods -n cineflow -w
```

### Health Verification

```bash
# Check API health
curl https://api.cineflow.ai/health

# Run smoke tests
./scripts/deploy/smoke-tests.sh production

# Run integration tests
./scripts/deploy/integration-tests.sh production

# Verify streaming
./scripts/deploy/test-streaming.sh production
```

### Post-Deployment

```bash
# Check CloudWatch logs
aws logs tail /aws/eks/cineflow-production --follow

# Monitor metrics in Grafana
# http://grafana.cineflow.ai

# Check Jaeger traces
# http://jaeger.cineflow.ai

# Monitor costs
aws ce get-cost-and-usage \
    --time-period Start=2024-01-01,End=2024-01-31 \
    --granularity DAILY \
    --metrics BlendedCost
```

## Rolling Updates

### Zero-Downtime Updates

```bash
# Update deployment with rolling update strategy
kubectl set image deployment/api-gateway \
    api-gateway=cineflow/api-gateway:v2.0.0 \
    -n cineflow

# Monitor rollout
kubectl rollout status deployment/api-gateway -n cineflow

# Rollback if needed
kubectl rollout undo deployment/api-gateway -n cineflow
```

### Blue-Green Deployment

```bash
# Deploy new version alongside current
kubectl apply -f infrastructure/k8s/api-gateway-blue-green.yaml

# Switch traffic to new version
kubectl patch service api-gateway \
    -p '{"spec":{"selector":{"version":"green"}}}' \
    -n cineflow

# Monitor metrics
sleep 300

# If issues, revert
kubectl patch service api-gateway \
    -p '{"spec":{"selector":{"version":"blue"}}}' \
    -n cineflow
```

## Disaster Recovery

### Backup Strategy

```bash
# Daily automated backups (configured in Terraform)
# - PostgreSQL snapshots: 30-day retention
# - S3 assets: Versioning enabled
# - Redis: AOF persistence

# Manual backup
aws rds create-db-snapshot \
    --db-instance-identifier cineflow-prod \
    --db-snapshot-identifier cineflow-prod-manual-$(date +%Y%m%d)
```

### Recovery Procedures

```bash
# Restore from RDS snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier cineflow-prod-restored \
    --db-snapshot-identifier cineflow-prod-backup-20240115

# Restore S3 assets
aws s3 sync \
    s3://cineflow-assets-prod \
    s3://cineflow-assets-prod-restored

# Point services to recovered resources
kubectl patch deployment api-gateway \
    -p '{"spec":{"template":{"spec":{"env":[{"name":"DATABASE_URL","value":"..."}]}}}}' \
    -n cineflow
```

## Scaling

### Horizontal Scaling

```bash
# Scale API Gateway
kubectl scale deployment api-gateway \
    --replicas=10 -n cineflow

# Verify scaling
kubectl get hpa -n cineflow
```

### Vertical Scaling

```bash
# Update resource requests/limits
kubectl set resources deployment api-gateway \
    --requests=cpu=2,memory=2Gi \
    --limits=cpu=4,memory=4Gi \
    -n cineflow
```

### Auto-Scaling Configuration

```yaml
# Already configured in Helm values with:
# - Min replicas: 3
# - Max replicas: 10
# - Target CPU: 70%
# - Target Memory: 80%
```

## Troubleshooting

### Service Not Starting

```bash
# Check pod logs
kubectl logs -n cineflow <pod-name>

# Describe pod for events
kubectl describe pod -n cineflow <pod-name>

# Check resource constraints
kubectl top nodes
kubectl top pods -n cineflow
```

### Database Connection Issues

```bash
# Check RDS security groups
aws ec2 describe-security-groups \
    --query 'SecurityGroups[?GroupName==`cineflow-rds`]'

# Test connection
kubectl run -it --rm debug --image=postgres --restart=Never -n cineflow \
    -- psql postgresql://user:pass@rds-endpoint:5432/cineflow
```

### Performance Issues

```bash
# Check Prometheus metrics
# http://prometheus.cineflow.ai

# Analyze slow queries
kubectl exec -it <postgres-pod> -n cineflow \
    -- psql -U cineflow -d cineflow_db \
    -c "SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

## Cost Optimization

```bash
# Use Spot instances for non-critical workloads
# Configured in Terraform for GPU nodes

# Monitor costs with AWS Cost Explorer
aws ce create-cost-category-definition \
    --name CineFlowServices \
    --rules file://cost-category-rules.json

# Set up billing alerts
aws cloudwatch put-metric-alarm \
    --alarm-name cineflow-monthly-cost \
    --alarm-description "Alert when monthly AWS costs exceed threshold" \
    --metric-name EstimatedCharges \
    --namespace AWS/Billing \
    --statistic Maximum \
    --period 86400 \
    --threshold 10000 \
    --comparison-operator GreaterThanThreshold
```

## Maintenance Windows

### Scheduled Maintenance

- **Day:** Sunday
- **Time:** 02:00-06:00 UTC
- **Duration:** 4 hours

During maintenance:
- Database maintenance windows
- Security patches
- Helm chart updates
- Infrastructure upgrades

### Communication

- Notify stakeholders 48 hours in advance
- Post status page updates
- Monitor support channels

## Security

### SSL/TLS Certificates

```bash
# Using AWS Certificate Manager
aws acm request-certificate \
    --domain-name api.cineflow.ai \
    --validation-method DNS
```

### Secrets Management

```bash
# Store secrets in AWS Secrets Manager
aws secretsmanager create-secret \
    --name cineflow-prod-secrets \
    --secret-string file://secrets.json

# Reference in Kubernetes
kubectl create secret generic cineflow-secrets \
    --from-literal=username=$(aws secretsmanager get-secret-value \
        --secret-id cineflow-prod-secrets \
        --query 'SecretString' | jq -r '.username')
```

## Monitoring & Observability

All deployments include:
- Prometheus for metrics
- Grafana for visualization
- Jaeger for distributed tracing
- ELK stack for logging
- CloudWatch for AWS native monitoring

See `/docs/MONITORING.md` for detailed configuration.

---

For support, open an issue on GitHub or contact dev@cineflow.ai
