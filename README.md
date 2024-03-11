# Kyverno

![Test Workflow](https://github.com/kadras-io/package-for-kyverno/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/package-for-kyverno/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Twitter](https://img.shields.io/static/v1?label=Twitter&message=Follow&color=1DA1F2)](https://twitter.com/kadrasIO)

A Carvel package for [Kyverno](https://kyverno.io), a policy engine designed for Kubernetes. It can validate, mutate, and generate configurations using admission controls and background scans.

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.27+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

  ```shell
  kapp deploy -a kapp-controller -y \
    -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
  ```

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
>   ```shell
>   kctrl package available list -p kyverno.packages.kadras.io -n kadras-system
>   ```

Verify the installed packages and their status:

  ```shell
  kctrl package installed list -n kadras-system
  ```

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.
For documentation specific to Kyverno, check out [kyverno.io](https://kyverno.io).

## 🎯&nbsp; Configuration

The Kyverno package can be customized via a `values.yml` file.

  ```yaml
  tracing:
    enabled: true
    endpoint: opentelemetrycollector.kyverno.svc.cluster.local
    port: 4317
  ```

Reference the `values.yml` file from the `kctrl` command when installing or upgrading the package.

  ```shell
  kctrl package install -i kyverno \
    -p kyverno.packages.kadras.io \
    -v ${VERSION} \
    -n kadras-system \
    --values-file values.yml
  ```

### Values

The Kyverno package has the following configurable properties.

<details><summary>Configurable properties</summary>

| Config | Default | Description |
|-------|-------------------|-------------|
| `optional_components.background_controller` | `true` | Whether to deploy the Background Controller, responsible for processing of generate and mutate-existing rules. |
| `optional_components.cleanup_controller` | `true` | Whether to deploy the Cleanup Controller, responsible for processing `CleanupPolicy` resources. |
| `optional_components.reports_controller` | `true` | Whether to deploy the Reports Controller, responsible for handling `PolicyReport` resources. |
| `ca_cert_data` | `""` | PEM-encoded certificate data to trust TLS connections with a custom CA. |

Settings for the controllers.

| Config | Default | Description |
|-------|-------------------|-------------|
| `admission_controller.replicas` | `1` | The number of replicas for the Admission Controller. In order to enable high availability, it should be at least 3 (2 is not permitted). |
| `background_controller.replicas` | `1` | The number of replicas for the Background Controller. In order to enable high availability, it should be greater than 1. |
| `cleanup_controller.replicas` | `1` | The number of replicas for the Cleanup Controller. In order to enable high availability, it should be greater than 1. |
| `reports_controller.replicas` | `1` | The number of replicas for the Reports Controller. In order to enable high availability, it should be greater than 1. |

Settings for logging.

| Config | Default | Description |
|-------|-------------------|-------------|
| `logging.level` | `2` | Number of the log level verbosity (from `1` to `6`). |
| `logging.encoding` | `text` | Log encoding format. Options: `text`, `json`. |

Settings for metrics.

| Config | Default | Description |
|-------|-------------------|-------------|
| `metrics.type` | `prometheus` | Whether to use OpenTelemetry (`grpc`) or Prometheus (`prometheus`) for exporting metrics. |
| `metrics.collector` | `""` | The endpoint where the OpenTelemetry-based collector receives telemetry data. For example, `opentelemetrycollector.kyverno.svc.cluster.local:4317`. |

Settings for tracing.

| Config | Default | Description |
|-------|-------------------|-------------|
| `tracing.enabled` | `false` | Whether to configure Kyverno to export OpenTelemetry traces to a distributed tracing backend. |
| `tracing.endpoint` | `""` | The endpoint where the distributed tracing backend accepts OpenTelemetry traces. For example, `opentelemetrycollector.kyverno.svc.cluster.local`. |
| `tracing.port` | `4317` | The port exposed by the distributed tracing backend to accept OpenTelemetry traces. |
| `tracing.ca_cert_secret` | `""` | The Secret containing the certificate which is used by the Opentelemetry Tracing Client. If empty string is set, an insecure connection will be used. |

Settings for the corporate proxy.

| Config | Default | Description |
|-------|-------------------|-------------|
| `proxy.https_proxy` | `""` | The HTTPS proxy to use for network traffic. |
| `proxy.http_proxy` | `""` | The HTTP proxy to use for network traffic. |
| `proxy.no_proxy` | `""` | A comma-separated list of hostnames, IP addresses, or IP ranges in CIDR format that should not use the proxy. |

</details>

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.
