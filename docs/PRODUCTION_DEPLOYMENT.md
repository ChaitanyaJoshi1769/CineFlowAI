# CineFlow AI Production Deployment Guide

## Pre-Deployment Checklist

- [ ] All tests passing (unit, integration, e2e)
- [ ] Security scan completed
- [ ] Load testing passed (1000+ req/s)
- [ ] Database backups configured
- [ ] Monitoring and alerting set up
- [ ] Disaster recovery plan documented
- [ ] Team trained on runbooks

## Deployment Steps

### 1. Infrastructure Setup

```bash
# Initialize Terraform
terraform init -backend-config="bucket=cineflow-state"

# Plan deployment
terraform plan -var-file="prod.tfvars" -out=tfplan

# Apply changes
terraform apply tfplan
```

### 2. Database Migration

```bash
# Run migrations
psql -h db.production -U admin -d cineflow < migrations/001_init.sql
psql -h db.production -U admin -d cineflow < migrations/002_core.sql

# Verify
psql -h db.production -U admin -d cineflow -c "SELECT COUNT(*) FROM users;"
```

### 3. Service Deployment

```bash
# Deploy with Helm
helm repo add cineflow https://charts.cineflow.ai
helm upgrade --install cineflow cineflow/cineflow \
  --namespace production \
  --values values-prod.yaml

# Verify rollout
kubectl rollout status deployment/api-gateway -n production
```

### 4. Health Verification

```bash
# Check API health
curl https://api.cineflow.ai/health

# Monitor logs
kubectl logs -f deployment/api-gateway -n production

# Check metrics
# Visit https://grafana.cineflow.ai
```

## Rollback Procedure

If issues occur:

```bash
# Helm rollback
helm rollback cineflow -n production

# Verify rollback
kubectl rollout status deployment/api-gateway -n production
```

## Monitoring

Key metrics to watch:
- Request latency (target: < 100ms p99)
- Error rate (target: < 0.1%)
- Video generation success rate (target: > 99%)
- Database connection pool utilization (target: < 80%)

## Support

- Slack channel: #cineflow-incidents
- PagerDuty: https://cineflow.pagerduty.com
- Runbooks: /runbooks directory
