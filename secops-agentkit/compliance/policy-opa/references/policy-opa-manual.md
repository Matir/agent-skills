# Open Policy Agent (OPA) Manual

## Policy Development (Rego)

### Kubernetes Pod Security Example
```rego
package kubernetes.admission
import future.keywords.contains
import future.keywords.if

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Privileged containers are not allowed: %v", [container.name])
}
```

### SOC2 Compliance Example
```rego
package compliance.soc2
import future.keywords.if

# CC6.1: Logical and physical access controls
deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.metadata.labels["data-classification"]
    msg := "SOC2 CC6.1: All deployments must have data-classification label"
}
```

## Testing Policies
Write unit tests in Rego to validate policy logic:
```rego
package kubernetes.admission_test
import data.kubernetes.admission

test_deny_privileged_container {
    input := { "request": { "kind": {"kind": "Pod"}, "object": { "spec": { "containers": [{ "name": "nginx", "securityContext": {"privileged": true} }] } } } }
    count(admission.deny) > 0
}
```
Run tests: `opa test . --verbose`

## CI/CD Integration

### GitHub Actions
```yaml
- name: Run Policy Tests
  run: opa test policies/ --verbose
- name: Evaluate Configuration
  run: opa eval --data policies/ --input deployments/ --format pretty 'data.compliance.violations'
```

### GitLab CI
```yaml
policy-validation:
  image: openpolicyagent/opa:latest
  script:
    - opa test policies/ --verbose
    - opa eval --data policies/ --input configs/ --format pretty 'data.compliance.violations'
```

## Common Patterns
- **IaC Validation**: Validate Terraform `plan` output before deployment.
- **Admission Control**: Use OPA Gatekeeper to enforce policies at the cluster level.
- **API Authz**: Implement attribute-based access control (ABAC) for microservices.
- **Data Classification**: Enforce labels on cloud resources based on data sensitivity.

## Troubleshooting
- **Unexpected Results**: Use `--explain full` to trace policy evaluation logic.
- **Syntax Errors**: Use `opa fmt` to format and identify structural issues.
- **Admission Issues**: Check Gatekeeper constraints (`kubectl get constraints`) and logs.
- **Performance**: Use policy bundles (`opa build`) and optimize rules to reduce complexity.
