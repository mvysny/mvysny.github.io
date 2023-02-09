---
layout: post
title: Let's Encrypt HTTPS/SSL for Microk8s
---

[Let's Encrypt](https://letsencrypt.org/) is an excellent way to have https for free.
The tutorial at [Microk8s addon: Cert Manager](https://microk8s.io/docs/addon-cert-manager)
lists all the steps but doesn't explain much. Here's what I learned.

The first step is to create the `ClusterIssuer` resource. Such resources are not bound to namespaces,
and therefore all apps are able to access that resource.
Once you create the `ClusterIssuer` resource, CertManager will know how to issue the certificate.
The resource tells CertManager to use the [ACME](https://en.wikipedia.org/wiki/Automatic_Certificate_Management_Environment)
protocol which is supported by Let's Encrypt: that's the `acme:` part.
The `server:` part points to the REST endpoint which implements ACME; in this case the
endpoint points towards Let's Encrypt. CertManager will generate a certificate authority
key to `letsencrypt-account-key` and you can view it in the Kubernetes Dashboard, under "Secrets".

The ACME protocol goes like this: the Certificate Authority (generated above) will produce a certificate for your DNS.
It will then ask Let's Encrypt to sign the certificate, in order for all browsers to trust that certificate.
Let's Encrypt will talk to certbot running on your DNS, to prove that you own the DNS. CertManager
will run certbot automatically during certificate obtain/renewal process.
CertManager will then store the signed certificate locally, and will provide it to the browser
when a https communication is attempted.

This is where the Ingress configuration comes to play. Ingress is annotated with
`cert-manager.io/cluster-issuer: letsencrypt` which tells CertManager that we are
going to issue a certificate for this site, and we'll use the `letsencrypt` ClusterIssuer.
Certbot will take a look at the `tls/secretName` configuration, and will run the ACME
certificate signing for all hosts mentioned, and will store the certificate to given secret `microbot-ingress-tls`.

The `rules/host` is also important: it then tells Ingress https engine which certificate for which host to use.
If you omit this, Ingress will use a self-signed Kubernetes certificate which will be rejected by the browsers.

## Multiple Ingress configurations pointing towards the same DNS

TODO
