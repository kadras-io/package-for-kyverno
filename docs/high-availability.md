# Configuring High Availability

High availability for the Kyverno controllers can be achieved when more than 1 replica is configured. Admission Controller and Cleanup Controller use a combination of stateless replication and leader election strategy based on the active/passive model. Background Controller and Reports Controller rely fully on a leader election strategy based on the active/passive model.

When more than 1 replica is configured (more than 2 for the Admission Controller), a `PodDisruptionBudget` is automatically created to prevent downtime during node unavailability.

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

For more information, check the Kyverno documentation for [high availability](https://kyverno.io/docs/high-availability/).
