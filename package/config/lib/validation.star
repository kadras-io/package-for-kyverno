load("@ytt:regexp", "regexp")

# Validation helpers used by the values schema.
# They must not depend on data values, since they run while the schema is evaluated.

_dns_label = "[a-z0-9]([-a-z0-9]*[a-z0-9])?"

def is_dns_label(value):
  return len(value) <= 63 and regexp.match("^" + _dns_label + "$", value)
end

# A Go duration made of hours, minutes, and seconds, like `1h`, `90m`, or `1h30m`.
def is_duration(value):
  return regexp.match("^([0-9]+h)?([0-9]+m)?([0-9]+s)?$", value) and value != ""
end

# The address of an OpenTelemetry collector Service in the cluster, like `http://otel-collector.observability.svc:4317`.
def is_in_cluster_otlp_endpoint(value):
  return regexp.match("^(http://)?" + _dns_label + "\\." + _dns_label + "(\\.svc(\\.cluster\\.local)?)?:[0-9]{1,5}$", value)
end
