# Upgrading

Upgrade Kyverno one minor version at a time, and read the [upgrade notes](https://kyverno.io/docs/installation/upgrading/) and the [release notes](https://github.com/kyverno/kyverno/releases) of each version first.

```shell
kctrl package installed update -i kyverno -v ${VERSION} -n kadras-system
```

After upgrading, rewrite the stored Kyverno resources to the current API versions of the CRDs with the [Kyverno CLI](https://kyverno.io/docs/kyverno-cli/). The Kyverno Helm chart does it automatically after each upgrade, the package doesn't.

```shell
for crd in $(kubectl get crd -o name | grep -E 'kyverno\.io$' | grep -v 'reports.kyverno.io' | cut -d/ -f2); do
  kyverno migrate --resource "$crd"
done
```

## Back up before uninstalling

The Kyverno CRDs are part of the package. Deleting the PackageInstall deletes them, and with them all the policies, policy exceptions, and policy reports in the cluster. The resource and policy webhooks Kyverno registers at runtime are deleted as well, so that they don't block the cluster.

The webhooks for policy exceptions, cleanup policies, and global context entries are left behind. They only match Kyverno resources, so they don't block the cluster. Delete them with:

```shell
kubectl delete validatingwebhookconfiguration -l webhook.kyverno.io/managed-by=kyverno
```

Back up the policies and policy exceptions before uninstalling the package. To keep the CRDs when the package is deleted, add this ytt overlay (see [configuration.md](configuration.md#ytt-overlays)):

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "CustomResourceDefinition"}), expects="1+"
---
metadata:
  #@overlay/match missing_ok=True
  annotations:
    #@overlay/match missing_ok=True
    kapp.k14s.io/delete-strategy: orphan
```
