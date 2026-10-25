# Corporate Proxy

When running Kyverno behind a corporate proxy, configure the controllers to reach external services through it: the container registries, when verifying images, and the services called by policies.

```yaml
proxy:
  http_proxy: http://proxy.example.com:3128
  https_proxy: http://proxy.example.com:3128
  no_proxy: .svc,.cluster.local,10.0.0.0/8
```

Include in `no_proxy` the address of the Kubernetes API server and the Pod and Service networks, so that the cluster traffic doesn't go through the proxy. See [proxy](https://kyverno.io/docs/installation/customization/#proxy).
