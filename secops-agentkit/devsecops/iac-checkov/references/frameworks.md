# Checkov Framework-Specific Workflows

Detailed workflows for different IaC frameworks.

## Terraform

**Scan Terraform with Variable Files:**

```bash
# Scan with tfvars
checkov -d ./terraform --var-file ./terraform.tfvars

# Download and scan external modules
checkov -d ./terraform --download-external-modules true

# Skip Terraform plan files
checkov -d ./terraform --skip-path terraform.tfstate
```

**Common Terraform Checks:**
- CKV_AWS_19: Ensure S3 bucket has server-side encryption
- CKV_AWS_21: Ensure S3 bucket has versioning enabled
- CKV_AWS_23: Ensure Security Group ingress is not open to 0.0.0.0/0
- CKV_AWS_40: Ensure IAM policies don't use wildcard actions
- CKV_AWS_61: Ensure RDS database has encryption at rest enabled

## Kubernetes

**Scan Kubernetes Manifests:**

```bash
# Scan all YAML manifests
checkov -d ./k8s --framework kubernetes

# Scan Helm chart
checkov -d ./helm-chart --framework helm

# Scan kustomize output
kustomize build ./overlay/prod | checkov -f - --framework kubernetes
```

**Common Kubernetes Checks:**
- CKV_K8S_8: Ensure Liveness Probe is configured
- CKV_K8S_10: Ensure CPU requests are set
- CKV_K8S_11: Ensure CPU limits are set
- CKV_K8S_14: Ensure container image is not latest
- CKV_K8S_16: Ensure container is not privileged
- CKV_K8S_22: Ensure read-only root filesystem
- CKV_K8S_28: Ensure container capabilities are minimized

## CloudFormation

**Scan CloudFormation Templates:**

```bash
# Scan CloudFormation template
checkov -f ./cloudformation/stack.yaml --framework cloudformation

# Scan AWS SAM template
checkov -f ./sam-template.yaml --framework serverless
```

## Dockerfile

**Scan Dockerfiles for Security Issues:**

```bash
# Scan Dockerfile
checkov -f ./Dockerfile --framework dockerfile

# Common issues detected:
# - Running as root user
# - Using :latest tag
# - Missing HEALTHCHECK
# - Exposing sensitive ports
```

## Baseline and Drift Detection

### Create Security Baseline

Establish baseline for existing infrastructure:

```bash
# Create baseline (first scan)
checkov -d ./terraform --create-baseline

# This creates .checkov.baseline file with current findings
```

### Detect New Issues (Drift)

Compare subsequent scans against baseline:

```bash
# Compare against baseline - only fail on NEW issues
checkov -d ./terraform --baseline .checkov.baseline

# This allows existing issues while preventing new ones
```

**Use Cases:**
- Gradual remediation of legacy infrastructure
- Focus on preventing new security debt
- Phased compliance adoption
