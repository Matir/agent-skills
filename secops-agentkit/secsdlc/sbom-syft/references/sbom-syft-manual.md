# Syft SBOM Generator Manual

## Core Workflows

### 1. Container Image SBOM Generation
```bash
# Generate CycloneDX JSON for a container image
syft <image-name:tag> -o cyclonedx-json=sbom-cyclonedx.json

# Generate multiple formats simultaneously
syft <image-name:tag> \
  -o cyclonedx-json=sbom-cyclonedx.json \
  -o spdx-json=sbom-spdx.json \
  -o syft-json=sbom-syft.json
```

### 2. Filesystem and Application Scanning
```bash
# Scan a directory structure
syft dir:/path/to/project -o cyclonedx-json=app-sbom.json
```

### 3. Vulnerability Scanning with Grype
```bash
# Generate SBOM and scan for vulnerabilities
syft <target> -o cyclonedx-json=sbom.json
grype sbom:sbom.json -o json --file vulnerabilities.json
```

### 4. Signed SBOM Attestation
```bash
# Generate SBOM
syft <image> -o cyclonedx-json=sbom.json

# Create and sign attestation with cosign
cosign attest --predicate sbom.json --type cyclonedx <image>

# Verify attestation
cosign verify-attestation --type cyclonedx <image>
```

## Supported Ecosystems
Syft detects packages across 28+ ecosystems including:
- **Languages**: Go, Java, JavaScript, Python, Rust, Ruby, PHP, Swift, Dotnet, C/C++, Dart.
- **OS Packages**: Alpine (apk), Debian/Ubuntu (dpkg), Red Hat (RPM).
- **Images**: OCI, Docker, Singularity.

## Output Formats
| Format | Use Case |
|--------|----------|
| `cyclonedx-json` | Modern SBOM standard, wide tool support |
| `spdx-json` | Linux Foundation standard |
| `syft-json` | Syft native format (most detail) |
| `github-json` | GitHub dependency submission |

## Common Patterns

### Multi-Architecture Image Scanning
```bash
syft --platform all <image> -o cyclonedx-json
```

### Private Registry Authentication
```bash
export SYFT_REGISTRY_AUTH_USERNAME=user
export SYFT_REGISTRY_AUTH_PASSWORD=pass
syft registry.example.com/private/image:tag -o cyclonedx-json
```

### OCI Archive Scanning
```bash
syft oci-archive:nginx.tar -o cyclonedx-json=sbom.json
```

### Comparing SBOMs
```bash
# Use jq to find differences between two syft-json SBOMs
jq -s '{"added": (.[1].artifacts - .[0].artifacts), "removed": (.[0].artifacts - .[1].artifacts)}' sbom-v1.json sbom-v2.json
```

## Configuration (`.syft.yaml`)
```yaml
package:
  cataloger:
    scope: all-layers
exclude:
  - "**/test/**"
  - "**/node_modules/**"
log:
  level: warn
```

## Troubleshooting
- **Missing Packages**: Try `--scope all-layers` to ensure all layers are scanned.
- **Registry Failures**: Ensure `docker login` is successful or provide explicit credentials in environment variables or config.
- **Performance**: Disable unindexed archive scanning in `.syft.yaml` under `package.search.unindexed-archives: false`.

## References
- [Syft GitHub Repository](https://github.com/anchore/syft)
- [Anchore SBOM Documentation](https://anchore.com/sbom/)
- [CycloneDX Specification](https://cyclonedx.org/)
- [SPDX Specification](https://spdx.dev/)
