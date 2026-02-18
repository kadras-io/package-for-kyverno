# Configuring Observability

Monitor and observe the operation of Kyverno using logs, metrics, and traces.

## Logs

The log verbosity and encoding format for the Kyverno controllers can be configured.

```yaml
logging:
  level: 2
  encoding: text
```

For more information, check Kyverno documentation for [logs](https://kyverno.io/docs/installation/customization/#container-flags).

## Metrics

The Kyverno controllers expose Prometheus metrics by default. This package comes pre-configured with the necessary annotations to let Prometheus scrape metrics automatically from the Kyverno controllers.

If you want to export metrics based on the OpenTelemetry format rather than Prometheus, you need to configure the OpenTelemetry endpoint where the controllers will push the metrics using gRPC.

```yaml
metrics:
  type: grpc
  collector: opentelemetrycollector.kyverno.svc.cluster.local:4317
```

For more information, check the Kyverno documentation for [metrics](https://kyverno.io/docs/monitoring/).

## Traces

OpenTelemetry instrumentation is provided for Kyverno. By default, the instrumentation is disabled. You can enable the generation of traces and configure how they are exported to an OpenTelemetry-compatible distributed tracing backend.

```yaml
tracing:
  enabled: true
  endpoint: opentelemetrycollector.kyverno.svc.cluster.local
  port: 4317
```

For more information, check the Kyverno documentation for [traces](https://kyverno.io/docs/tracing/).

## Dashboards

If you use the Grafana observability stack, you can refer to this [dashboard](https://kyverno.io/docs/guides/monitoring/#grafana-dashboard) as a foundation to build your own.
