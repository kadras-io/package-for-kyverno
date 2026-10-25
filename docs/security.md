# Security

The controllers are hardened following the [Kyverno security guide](https://kyverno.io/docs/guides/security/).

## Pod Security Standards

The controllers comply with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), enforced on the package namespace.

## Service account tokens

The service account tokens aren't auto-mounted. Each container mounts a projected token instead, which expires after an hour and is rotated by the kubelet.

## Network policies

The package can deny the inbound traffic to the controllers, except for:

* the admission requests from the Kubernetes API server to the admission and cleanup controllers, on port 9443;
* the metrics scraping, on port 8000, when metrics are exported with Prometheus.

```yaml
security:
  network_policies: true
```

The source of both isn't known in advance, so they're allowed from anywhere. The traffic from the kubelet, like health probes, is always allowed. The NetworkPolicies are named like the controllers: restrict them further with a ytt overlay (see [configuration.md](configuration.md#ytt-overlays)). On some platforms, like EKS with custom security groups and private GKE clusters, the control plane also needs a firewall rule to reach port 9443 on the nodes. See the [platform notes](https://kyverno.io/docs/installation/platform-notes/).

### Outbound traffic

The package doesn't restrict the outbound traffic, since its destinations depend on the cluster and the policies:

* all the controllers reach the Kubernetes API server (usually on port 443 or 6443) and the cluster DNS (port 53);
* the admission, background, and reports controllers reach the container registries when verifying images (port 443);
* policies can call external services, through the corporate proxy, if any.

To restrict it, create your own NetworkPolicies in the package namespace: they add up to the ones of the package. For example, to only allow the controllers to reach the cluster DNS and the Kubernetes API server, adjusting the API server ports to your cluster:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kyverno-egress
  namespace: kyverno
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/part-of: kyverno
  policyTypes:
  - Egress
  egress:
  - ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 6443
```

Port 443 also covers the container registries. To limit them to specific addresses, add a separate rule with `to.ipBlock`.

## Policy exceptions

[Policy exceptions](https://kyverno.io/docs/exceptions/) are disabled by default. When enabled, they're only accepted in a single namespace, so that you control who can create them. Accepting them from all namespaces isn't supported, since anyone able to create one could disable any policy.

```yaml
policy_exceptions:
  enabled: true
  namespace: kyverno-exceptions
```

The package doesn't create the namespace. The built-in `admin` ClusterRole allows creating exceptions, so only grant it there to the people who should manage them.

## Failure policy

When Kyverno doesn't respond, the requests matched by a policy are rejected, unless the policy sets the `Ignore` failure policy. To let all requests through instead, trading policy enforcement for cluster availability:

```yaml
webhooks:
  force_failure_policy_ignore: true
```

The `kube-system` namespace and the package namespace are excluded from the webhooks, so that the cluster and Kyverno itself can recover.
