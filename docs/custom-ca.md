# Configuring a Self-Signed Certificate for a Private Registry

If you need to interact with a private registry using a self-signed certificate, you can pass it as a PEM-encoded bundle when installing/upgrading the package.

```yaml
ca_cert_data: |
    -----BEGIN CERTIFICATE-----
    MIICvjCCAaYCCQDhcJuwMw6yZzANBgkqhkiG9w0BAQsFADAhMQswCQYDVQQGEwJE
    SzESMBAGA1UEAwwJa2FkcmFzLmlvMB4XDTIzMDEzMTIxMDQ0M1oXDTI4MDEzMTIx
    MDQ0M1owITELMAkGA1UEBhMCREsxEjAQBgNVBAMMCWthZHJhcy5pbzCCASIwDQYJ
    KoZIhvcNAQEBBQADggEPADCCAQoCggEBAK+rBzsOM95TDd1Ve7dTDJGHhP4snO8Y
    95rHl6LTdxe4x6uDQ7riqpV6uqCSaH0vQJZPhkdH/vgQRKtuNU1JrUNW/gY0t8pO
    ITkh8PBctzM8R+28IPQ80qA/vyGk4aaN/TZUMcYAtswk54Izy2M7ZnMvNEOiNSYs
    lHlKsj3oyrbkcWQrEcooPzsFoJZsMFnhJQjJ2MM+meSR2+x/edtS1+aw4/HUX9zw
    jkbqWoPMzBGjLzHqcb9V/GLg/x4P1BLAMaiRFF1mmxOMbNP2KmUdjiNBnDo0KZRb
    xm+898FF2yBWLLVs8ZMYpPGhmN7LSoNmLIueBrNrjau7K+8WePam8O0CAwEAATAN
    BgkqhkiG9w0BAQsFAAOCAQEAmq21ZJqoXXfs1U3HDk20+ay4HH9m76B1Vw5q5D9j
    t3sfjyl/RhvIObGoIGnrt59H+gfJ9aQFqm+2LeZHDCzDubHa+63Z7KQIoRO3uHGX
    XnEhiAckIaxllBhJeO/UJmhr833hKPnS4e2xHgI83oAyplec4UtoicJMmUGULZvS
    fZ81unl1Ia6j0MVQrGYG93T80DyiPyaGPnoLHQQpnbO3IXgQL+ZmtNUBP0wk7IiR
    71vOWfDFcY4Od3863+diyyL7uL7Nlfhl7bmbvmRjZ2HJadTi9pSlxLPDDJ6ATPIA
    83rObyM7bWgv+bpQlqZrNAZlLWb3ICBHFumx4CGh/g6pqg==
    -----END CERTIFICATE-----
```

For more information, check the Kyverno documentation for [self-signed certificates](https://kyverno.io/docs/writing-policies/verify-images/sigstore/#trust).
