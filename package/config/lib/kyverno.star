load("@ytt:data", "data")
load("@ytt:json", "json")
load("@ytt:struct", "struct")

# ###########
# COMPONENTS
# ###########

# The Deployment, container, and component label of each controller, as defined in the upstream manifest.
# The flags each controller accepts differ: `exceptions` and `registry` tell which ones support
# the policy exceptions and the registry client flags. `service` is the Service of the webhook it serves, if any.
def components():
  return [
    struct.encode({"key": "admission_controller", "deployment": "kyverno-admission-controller", "container": "kyverno", "component": "admission-controller", "service": "kyverno-svc", "exceptions": True, "registry": True}),
    struct.encode({"key": "background_controller", "deployment": "kyverno-background-controller", "container": "controller", "component": "background-controller", "service": None, "exceptions": True, "registry": True}),
    struct.encode({"key": "cleanup_controller", "deployment": "kyverno-cleanup-controller", "container": "controller", "component": "cleanup-controller", "service": "kyverno-cleanup-controller", "exceptions": False, "registry": False}),
    struct.encode({"key": "reports_controller", "deployment": "kyverno-reports-controller", "container": "controller", "component": "reports-controller", "service": None, "exceptions": True, "registry": True}),
  ]
end

def component_values(component):
  return getattr(data.values, component.key)
end

# The admission controller is always deployed, the others can be disabled.
def is_enabled(component):
  return component.key == "admission_controller" or component_values(component).enabled
end

def enabled_components():
  return [component for component in components() if is_enabled(component)]
end

# The labels selecting the Pods of a component, as in the upstream Deployments.
def component_selector(component):
  return {
    "app.kubernetes.io/component": component.component,
    "app.kubernetes.io/instance": "kyverno",
    "app.kubernetes.io/part-of": "kyverno",
  }
end

def component_labels(component):
  labels = component_selector(component)
  labels["app.kubernetes.io/name"] = component.deployment
  return labels
end

# ###########
# FLAGS
# ###########

# The controllers use the klog verbosity levels, where 2 is the default.
def logging_args():
  logging = data.values.observability.logging
  return {
    "loggingFormat": logging.format,
    "v": {"info": 2, "debug": 4, "trace": 6}[logging.level],
  }
end

# Splits an endpoint like `http://otel-collector.observability.svc:4317` into its address and port.
def _otlp_address_port(endpoint):
  if endpoint.startswith("http://"):
    endpoint = endpoint[len("http://"):]
  end
  return endpoint.rsplit(":", 1)
end

# Whether the controllers serve Prometheus metrics on port 8000, rather than pushing them via OTLP.
def prometheus_metrics_enabled():
  metrics = data.values.observability.metrics
  return metrics.enabled and metrics.exporter == "prometheus"
end

# With the OTLP exporter (`--otelConfig=grpc`), the controllers push the metrics to the collector at `--otelCollector`,
# on the port set by `--metricsPort`, instead of serving them on it.
def metrics_args():
  metrics = data.values.observability.metrics
  if not metrics.enabled:
    return {"disableMetrics": True}
  end
  if metrics.exporter == "prometheus":
    return {"disableMetrics": False, "otelConfig": "prometheus"}
  end
  address, port = _otlp_address_port(metrics.endpoint)
  args = {"disableMetrics": False, "otelConfig": "grpc", "otelCollector": address, "metricsPort": port}
  if metrics.ca_secret:
    args["transportCreds"] = metrics.ca_secret
  end
  return args
end

def tracing_args():
  tracing = data.values.observability.tracing
  if not tracing.enabled:
    return {}
  end
  address, port = _otlp_address_port(tracing.endpoint)
  args = {"enableTracing": True, "tracingAddress": address, "tracingPort": port}
  if tracing.ca_secret:
    args["tracingCreds"] = tracing.ca_secret
  end
  return args
end

# The flags computed from the package values. `<component>.args` is merged on top of them.
def component_args(component):
  namespace = data.values.namespace
  args = {}
  args.update(logging_args())
  args.update(metrics_args())
  args.update(tracing_args())

  if component.exceptions:
    exceptions = data.values.policy_exceptions
    args["enablePolicyException"] = exceptions.enabled
    if exceptions.enabled:
      args["exceptionNamespace"] = exceptions.namespace
    end
  end

  if component.registry:
    args["imagePullSecrets"] = "canonical-registry-credentials"
  end

  # The webhook certificates are stored in Secrets named after the Service and its namespace.
  if component.service:
    args["caSecretName"] = component.service + "." + namespace + ".svc.kyverno-tls-ca"
    args["tlsSecretName"] = component.service + "." + namespace + ".svc.kyverno-tls-pair"
  end

  if component.key == "admission_controller":
    args["backgroundServiceAccountName"] = "system:serviceaccount:" + namespace + ":kyverno-background-controller"
    args["reportsServiceAccountName"] = "system:serviceaccount:" + namespace + ":kyverno-reports-controller"
    args["webhookTimeout"] = data.values.webhooks.timeout_seconds
    args["forceFailurePolicyIgnore"] = data.values.webhooks.force_failure_policy_ignore
    # Without the reports controller, nothing would aggregate the admission reports.
    args["admissionReports"] = data.values.reports_controller.enabled
  elif component.key == "reports_controller":
    args["backgroundScanInterval"] = data.values.reports.background_scan_interval
  end

  for name, value in struct.decode(component_values(component).args).items():
    args[name.lstrip("-")] = value
  end
  return args
end

def _format(value):
  if type(value) == "bool":
    return "true" if value else "false"
  end
  return str(value)
end

# Merges the given flags into the upstream ones, keeping their order. New flags are appended,
# and flags set to null are removed.
def _merge_args(upstream, overrides):
  flags = {}
  for arg in upstream:
    name, _, value = arg.lstrip("-").partition("=")
    flags[name] = value
  end
  for name, value in overrides.items():
    if value == None:
      flags.pop(name, None)
    else:
      flags[name] = _format(value)
    end
  end
  return ["--" + name + "=" + value for name, value in flags.items()]
end

# The `via` function of the overlays replacing the upstream container args.
def args_merger(overrides):
  return lambda left, _: _merge_args(left, overrides)
end

# ###########
# CONFIG
# ###########

# The `kyverno` ConfigMap only holds strings: structured values are encoded as JSON, as upstream does.
def config_data():
  config = {}
  for key, value in struct.decode(data.values.config).items():
    config[key] = value if type(value) == "string" else json.encode(value)
  end
  return config
end
