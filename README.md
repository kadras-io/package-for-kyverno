# Kyverno

![Test Workflow](https://github.com/kadras-io/package-for-kyverno/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/package-for-kyverno/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Bluesky](https://img.shields.io/static/v1?label=Bluesky&message=Follow&color=1DA1F2)](https://bsky.app/profile/kadras.bsky.social)

A Carvel package for [Kyverno](https://kyverno.io), a policy engine designed for Kubernetes. It validates, mutates, generates, and cleans up resources via admission control and background scans, and verifies container images.

## ✨&nbsp; What's Included

* **Policy engine**. The Kyverno admission, background, cleanup, and reports controllers, supporting both the CEL-based policy types (`ValidatingPolicy`, `MutatingPolicy`, `GeneratingPolicy`, `ImageValidatingPolicy`, `DeletingPolicy`) and the legacy `ClusterPolicy`. The optional controllers can be disabled.
* **High availability**. Configurable replicas, protected by PodDisruptionBudgets, with the admission controller running with the `system-cluster-critical` priority.
* **Observability**. Structured logs, metrics via Prometheus or OpenTelemetry, and OpenTelemetry traces.
* **Security**. The controllers comply with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), mount the service account tokens only where needed, and can be isolated with network policies.

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.35+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

```shell
kapp deploy -a kapp-controller -y \
  -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

### Dependencies

Kyverno has no required dependencies. To authenticate with private registries, install [secretgen-controller](https://github.com/kadras-io/package-for-secretgen-controller) from the [Kadras package repository](https://github.com/kadras-io/kadras-packages).

### Installation

Add the Kadras [package repository](https://github.com/kadras-io/kadras-packages) to your Kubernetes cluster:

```shell
kctrl package repository add -r kadras-packages \
  --url ghcr.io/kadras-io/kadras-packages \
  -n kadras-system --create-namespace
```

<details><summary>Installation without package repository</summary>
The recommended way of installing the Kyverno package is via the Kadras <a href="https://github.com/kadras-io/kadras-packages">package repository</a>. If you prefer not using the repository, you can add the package definition directly using <a href="https://carvel.dev/kapp/docs/latest/install"><code>kapp</code></a> or <code>kubectl</code>.

```shell
kubectl create namespace kadras-system
kapp deploy -a kyverno-package -n kadras-system -y \
  -f https://github.com/kadras-io/package-for-kyverno/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/package-for-kyverno/releases/latest/download/package.yml
```
</details>

Install the Kyverno package:

```shell
kctrl package install -i kyverno \
  -p kyverno.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system
```

> **Note**
> You can find the `${VERSION}` value by retrieving the list of package versions available in the Kadras package repository installed on your cluster.
> 
> ```shell
> kctrl package available list -p kyverno.packages.kadras.io -n kadras-system
> ```

Verify the installed packages and their status:

```shell
kctrl package installed list -n kadras-system
```

### Try It Out

Require a `team` label on all Pods:

```shell
kubectl apply -f - <<EOF
apiVersion: policies.kyverno.io/v1
kind: ValidatingPolicy
metadata:
  name: require-team-label
spec:
  validationActions:
    - Deny
  matchConstraints:
    resourceRules:
      - apiGroups: [""]
        apiVersions: [v1]
        operations: [CREATE, UPDATE]
        resources: [pods]
  validations:
    - expression: "has(object.metadata.labels) && 'team' in object.metadata.labels"
      message: Pods must have the team label.
EOF
```

Check that a Pod without the label is denied, and one with the label is accepted:

```shell
kubectl run unlabeled --image=nginx --dry-run=server
kubectl run labeled --image=nginx --labels=team=platform --dry-run=server
```

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.
For documentation specific to Kyverno, check out [kyverno.io](https://kyverno.io).

Features:

* [Policies](docs/policies.md)
* [High availability](docs/high-availability.md)
* [Observability](docs/observability.md)
* [Security](docs/security.md)

Operations:

* [Configuration and ytt overlays](docs/configuration.md)
* [Custom certificate authorities](docs/custom-ca.md)
* [Corporate proxy](docs/corporate-proxy.md)
* [Upgrading](docs/upgrade.md)
* [Verifying the release](docs/verify-release.md)

## 🎯&nbsp; Configuration

The Kyverno package can be customized via a `values.yml` file.

```yaml
admission_controller:
  replicas: 3
policy_exceptions:
  enabled: true
  namespace: kyverno-exceptions
observability:
  logging:
    format: json
```

Reference the `values.yml` file from the `kctrl` command when installing or upgrading the package.

```shell
kctrl package install -i kyverno \
  -p kyverno.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system \
  --values-file values.yml
```

The flags of each controller and the `kyverno` ConfigMap can be customized beyond the values, as well as any resource via ytt overlays. See [configuration.md](docs/configuration.md).

### Values

The Kyverno package has the following configurable properties.

<details><summary>Configurable properties</summary>

<!-- values-table:start -->

| Config | Default | Description |
|--------|---------|-------------|
| `namespace` | `"kyverno"` | The namespace in which to deploy Kyverno. |
| `admission_controller.replicas` | `1` | The number of replicas. All replicas serve admission requests. For high availability, Kyverno requires at least 3, and doesn't support 2. With more than 1 replica, a PodDisruptionBudget is created. |
| `admission_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://kyverno.io/docs/installation/customization/#container-flags. |
| `background_controller.enabled` | `true` | Whether to deploy the background controller. |
| `background_controller.replicas` | `1` | The number of replicas. Additional replicas are standby via leader election. With more than 1 replica, a PodDisruptionBudget is created. |
| `background_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://kyverno.io/docs/installation/customization/#container-flags. |
| `cleanup_controller.enabled` | `true` | Whether to deploy the cleanup controller. |
| `cleanup_controller.replicas` | `1` | The number of replicas. With more than 1 replica, a PodDisruptionBudget is created. |
| `cleanup_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://kyverno.io/docs/installation/customization/#container-flags. |
| `reports_controller.enabled` | `true` | Whether to deploy the reports controller. When disabled, the admission controller doesn't produce admission reports either. |
| `reports_controller.replicas` | `1` | The number of replicas. Additional replicas are standby via leader election. With more than 1 replica, a PodDisruptionBudget is created. |
| `reports_controller.args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://kyverno.io/docs/installation/customization/#container-flags. |
| `policy_exceptions.enabled` | `false` | Whether to accept policy exceptions. |
| `policy_exceptions.namespace` | `""` | The only namespace where policy exceptions are accepted. Restrict who can create resources in it, since an exception can disable any policy. |
| `webhooks.timeout_seconds` | `10` | How long the Kubernetes API server waits for Kyverno to respond to an admission request, in seconds. |
| `webhooks.force_failure_policy_ignore` | `false` | Whether to let requests through when Kyverno doesn't respond, for all policies, instead of their failure policy. It trades policy enforcement for cluster availability. |
| `reports.background_scan_interval` | `"1h"` | How often existing resources are scanned against the policies, as a duration. |
| `config` | `{}` | Settings merged into the `kyverno` ConfigMap, with structured values encoded as JSON. See https://kyverno.io/docs/installation/customization/#configmap-keys. |
| `ca_cert_data` | `""` | PEM-encoded certificates of additional certificate authorities to trust, for example to reach a private container registry. The system ones are still trusted. |
| `observability.logging.level` | `"info"` | The log level of the controllers. |
| `observability.logging.format` | `"text"` | The format of the logs. |
| `observability.metrics.enabled` | `true` | Whether to produce metrics. |
| `observability.metrics.exporter` | `"prometheus"` | How the metrics are exported. With `prometheus`, the controllers expose them on port 8000, and their Pods are annotated for scraping. With `otlp`, they push them via OTLP/gRPC to `endpoint`. |
| `observability.metrics.endpoint` | `""` | The OTLP/gRPC endpoint of an in-cluster OpenTelemetry collector, in the form `[http://]<service>.<namespace>[.svc[.cluster.local]]:<port>`. Required with the `otlp` exporter. |
| `observability.metrics.ca_secret` | `""` | The name of a Secret in the package namespace with the CA certificate (`ca.pem`) to verify the collector, with the `otlp` exporter. If empty, the connection is insecure. |
| `observability.tracing.enabled` | `false` | Whether to export traces via OTLP/gRPC. |
| `observability.tracing.endpoint` | `""` | The OTLP/gRPC endpoint of an in-cluster OpenTelemetry collector, in the form `[http://]<service>.<namespace>[.svc[.cluster.local]]:<port>`. |
| `observability.tracing.ca_secret` | `""` | The name of a Secret in the package namespace with the CA certificate (`ca.pem`) to verify the collector. If empty, the connection is insecure. |
| `security.network_policies` | `false` | Whether to restrict the inbound traffic to the controllers via NetworkPolicies, allowing only the admission requests and the metrics scraping. |
| `proxy.http_proxy` | `""` | The HTTP proxy to use for network traffic. |
| `proxy.https_proxy` | `""` | The HTTPS proxy to use for network traffic. |
| `proxy.no_proxy` | `""` | A comma-separated list of hostnames, IP addresses, or IP ranges in CIDR format that should not use the proxy. |

<!-- values-table:end -->

</details>

## 🛠️&nbsp; Development

The development environment is defined with [devenv](https://devenv.sh). Enter it with `devenv shell`, or automatically with [direnv](https://direnv.net) after running `direnv allow`. Run `task --list` to see all the available tasks.

```shell
# Run the unit tests, which render the package and check the result without a cluster.
task test:config

# Create a local kind cluster and run the integration tests on it.
task cluster:setup
task test:integration

# Deploy the package from the local sources to the current cluster.
task dev

# Update the table of configurable values in this README after changing the values schema.
task docs:values
```

The unit tests are described in [test/unit/README.md](test/unit/README.md).

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.
