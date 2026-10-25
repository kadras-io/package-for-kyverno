# Custom Certificate Authorities

If Kyverno needs to reach services with certificates signed by a private certificate authority, like a private container registry when verifying images, add the PEM-encoded certificates of the authority to the package values.

```yaml
ca_cert_data: |
  -----BEGIN CERTIFICATE-----
  MIICvjCCAaYCCQDhcJuwMw6yZzANBgkqhkiG9w0BAQsFADAhMQswCQYDVQQGEwJE
  ...
  -----END CERTIFICATE-----
```

The certificates are stored in the `kyverno-ca-certificates` Secret and mounted in all the controllers, which trust them in addition to the system certificate authorities.
