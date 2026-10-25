# Policies

The package installs the Kyverno policy engine, without any policies. Write your own, or start from the [Kyverno policy library](https://kyverno.io/policies/). Prefer the CEL-based policy types: the legacy ones, like `ClusterPolicy`, are deprecated since Kyverno 1.19. See the [policy types](https://kyverno.io/docs/policy-types/overview/).

If you disable a controller, the policies it processes have no effect:

* the background controller processes the generating policies and the mutations of existing resources;
* the cleanup controller processes the deleting and cleanup policies;
* the reports controller produces the policy reports. Without it, the admission controller doesn't produce admission reports either.

The reports controller scans the existing resources every hour by default.

```yaml
reports:
  background_scan_interval: 30m
```
