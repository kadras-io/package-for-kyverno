# Observability

## Logs

The log level and format apply to all the Kyverno controllers.

```yaml
observability:
  logging:
    level: info
    format: json
```

* `level` is one of `info`, `debug`, `trace`. They map to the verbosity levels 2, 4, and 6 used by Kyverno.
* `format` is one of `text` and `json`.

## Metrics

By default, all the controllers expose metrics in the Prometheus format on port 8000 (`/metrics`). Their Pods are annotated for Prometheus scraping (`prometheus.io/scrape`, `prometheus.io/port`, `prometheus.io/path`). To disable the metrics and remove the annotations:

```yaml
observability:
  metrics:
    enabled: false
```

If you use the Prometheus Operator, create a PodMonitor instead:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: kyverno
  namespace: kyverno
spec:
  selector:
    matchLabels:
      app.kubernetes.io/part-of: kyverno
  podMetricsEndpoints:
    - targetPort: 8000
```

Which metrics and labels are exposed is configured via the `kyverno-metrics` ConfigMap: customize it with a ytt overlay (see [configuration.md](configuration.md#ytt-overlays)). See the [metrics reference](https://kyverno.io/docs/reference/metrics/) and the [Grafana dashboard](https://kyverno.io/docs/guides/monitoring/).

### OpenTelemetry

The controllers can push the metrics via OTLP/gRPC to an OpenTelemetry collector in the cluster, instead of exposing them for scraping.

```yaml
observability:
  metrics:
    exporter: otlp
    endpoint: http://otel-collector.observability.svc:4317
```

With the `otlp` exporter, the controllers don't listen on port 8000, and their Pods aren't annotated for scraping. To verify the collector with TLS, create a Secret in the package namespace with its CA certificate in the `ca.pem` key, and set its name in `observability.metrics.ca_secret`.

## Traces

The controllers can export traces via OTLP/gRPC to an OpenTelemetry collector in the cluster.

```yaml
observability:
  tracing:
    enabled: true
    endpoint: http://otel-collector.observability.svc:4317
```

To verify the collector with TLS, create a Secret in the package namespace with its CA certificate in the `ca.pem` key, and set its name in `observability.tracing.ca_secret`.
