# High Availability

By default, the package runs 1 replica of each Kyverno controller. For production, the [Kyverno documentation](https://kyverno.io/docs/guides/high-availability/) recommends 3 replicas of the admission controller and 2 of the others.

```yaml
admission_controller:
  replicas: 3
background_controller:
  replicas: 2
cleanup_controller:
  replicas: 2
reports_controller:
  replicas: 2
```

* The **admission controller** follows an active/active model: all replicas serve the admission requests from the Kubernetes API server. More replicas improve both availability and throughput. Kyverno requires at least 3 replicas for high availability and doesn't support 2, so the package rejects that value.
* The **background controller** and the **reports controller** follow an active/passive model: one replica is elected leader and does the work, the others are hot standby. More replicas improve availability, not throughput.
* The **cleanup controller** replicas all serve its webhook, and one is elected leader to run the cleanup.

The replicas are spread across nodes via pod anti-affinity rules defined upstream, on a best-effort basis. Single-node clusters keep working.

## Disruptions

With more than one replica, a PodDisruptionBudget keeps at least one replica of the controller available during voluntary disruptions, like node drains.

## Priority

The admission controller runs with the `system-cluster-critical` [priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). Some clusters only allow this priority class in the `kube-system` namespace. In that case, create a ResourceQuota in the package namespace that allows it.

## Resources

Tune the resources with a ytt overlay, as described in [configuration.md](configuration.md#resources).
