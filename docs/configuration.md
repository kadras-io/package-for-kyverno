# Configuration

The package values cover the decisions most installations need to make: which controllers to run, policy exceptions, high availability, observability, and security. Everything else can still be customized in three ways.

## Container flags

Each controller is configured via [container flags](https://kyverno.io/docs/installation/customization/#container-flags). The package computes them from the values and merges them into the upstream ones, then merges `<component>.args` on top, so its flags take precedence. The flags are written without the leading dashes, and a flag set to `null` is removed.

```yaml
admission_controller:
  args:
    clientRateLimitQPS: 500
    clientRateLimitBurst: 500
    generateValidatingAdmissionPolicy: false
background_controller:
  args:
    genWorkers: 20
reports_controller:
  args:
    clientRateLimitQPS: 500
    clientRateLimitBurst: 500
    backgroundScanWorkers: 4
```

Each controller accepts different flags, and an unknown flag prevents it from starting. Check the reference before adding one. A change rolls out the controller.

## ConfigMap

All the controllers read their dynamic configuration from the `kyverno` ConfigMap at runtime. `config` is merged into it, and structured values are encoded as JSON. See the [ConfigMap keys](https://kyverno.io/docs/installation/customization/#configmap-keys).

```yaml
config:
  generateSuccessEvents: true
  excludeGroups: system:nodes,system:serviceaccounts:kube-system
  webhookLabels:
    team: platform
```

The package already sets two of the keys, based on the namespace it's installed in. If you override them, keep the package namespace in them:

* `resourceFilters`: the requests Kyverno doesn't process, including the ones for its own resources and for the `kube-system` namespace. See [resource filters](https://kyverno.io/docs/installation/customization/#resource-filters).
* `webhooks`: the namespaces excluded from the webhooks, by default `kube-system` and the package namespace. See [namespace selectors](https://kyverno.io/docs/installation/customization/#namespace-selectors).

## ytt overlays

Any Kubernetes resource of the package can be customized with a [ytt overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/). Store it in a Secret and reference it from the PackageInstall via the `ext.packaging.carvel.dev/ytt-paths-from-secret-name.0` annotation.

```shell
kubectl create secret generic kyverno-overlays -n kadras-system --from-file=overlays.yml
kubectl annotate packageinstall kyverno -n kadras-system \
  ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=kyverno-overlays
```

### Resources

The upstream manifest sets resource requests and memory limits for each controller. See [scaling](https://kyverno.io/docs/installation/scaling/) to size them.

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "kyverno-admission-controller"}})
---
spec:
  template:
    spec:
      containers:
        #@overlay/match by="name"
        - name: kyverno
          resources:
            requests:
              cpu: 200m
              memory: 256Mi
            limits:
              memory: 768Mi
```

### Node placement

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment"}), expects=4
---
spec:
  template:
    spec:
      #@overlay/match-child-defaults missing_ok=True
      nodeSelector:
        node-restriction.kubernetes.io/reserved-for: platform
      #@overlay/match missing_ok=True
      tolerations:
        - key: node-restriction.kubernetes.io/reserved-for
          operator: Equal
          value: platform
          effect: NoExecute
```

Use `expects` to match the number of enabled controllers.

### Additional permissions

Policies that generate or mutate existing resources need the background controller to have permissions on them. Create a ClusterRole with the aggregation label of the controller, `rbac.kyverno.io/aggregate-to-<controller>: "true"`, instead of editing the ones of the package.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kyverno:background-controller:secrets
  labels:
    rbac.kyverno.io/aggregate-to-background-controller: "true"
rules:
  - apiGroups: [""]
    resources: [secrets]
    verbs: [create, update, delete]
```
