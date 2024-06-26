---
layout: post
title: Let's Encrypt HTTPS/SSL for Microk8s
---

[Let's Encrypt](https://letsencrypt.org/) is an excellent way to have https for free.
The tutorial at [Microk8s addon: Cert Manager](https://microk8s.io/docs/addon-cert-manager)
lists all the steps but doesn't explain much. Here's what I learned.

Go with the [tutorial at Microk8s addon: Cert Manager](https://microk8s.io/docs/addon-cert-manager);
I'll explain everything below.

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
`cert-manager.io/cluster-issuer: lets-encrypt` which tells CertManager that we are
going to issue a certificate for this site, and we'll use the `lets-encrypt` ClusterIssuer.
Certbot will take a look at the `tls/secretName` name (say it's `microbot-ingress-tls`), and will run the ACME
certificate signing for all hosts mentioned, and will store the certificate to given secret `microbot-ingress-tls`.

The `rules/host` is also important: it then tells Ingress https engine which certificate for which host to use.
If you omit this, Ingress will use a default certificate (by default self-signed Kubernetes certificate but can be changed, see below)
which will be rejected by the browsers.

## Multiple Ingress configurations pointing towards the same DNS

If you have multiple Ingress configuration resources for the same host split across multiple files,
the question is, which parts of the Ingress configuration should be repeated, and which parts
should not. There are two parts in question:

* The `cert-manager.io/cluster-issuer: lets-encrypt` annotation which activates CertManager auto-renewal; and
* `spec/tls` which configures Ingress HTTPS support for this resource.

I think that the `cert-manager.io/cluster-issuer: lets-encrypt` annotation may or may not
be repeated; if repeated, in the worst case CertManager may ask for signing too many times.
The `spec/tls` needs to be repeated otherwise Ingress HTTPS won't activate.

### When Annotation is not repeated

I was thinking of creating a very simple nginx static backend service; the sole purpose for it would be to activate CertManager
auto-renewal for `my-dns.com`.

The problem is that Secrets are namespaced and tied to that namespace; an app from a different namespace
can not obtain access to a secret from another namespace: [#8083](https://github.com/kubernetes/ingress-nginx/issues/8083)
and [#2170](https://github.com/kubernetes/ingress-nginx/issues/2170). But there's a way:
[Syncing Secrets Across Namespaces](https://cert-manager.io/docs/tutorials/syncing-secrets-across-namespaces/).

Looks like the [Nginx default certificate](https://kubernetes.github.io/ingress-nginx/user-guide/tls/#default-ssl-certificate)
is the simplest solution, but you can obviously make only one DNS the default one.

## Troubleshooting

Q: I have `Error from server (InternalError): error when creating "letsencrypt.yaml": Internal error occurred: failed calling webhook "webhook.cert-manager.io": failed to call webhook: Post "https://cert-manager-webhook.cert-manager.svc:443/mutate?timeout=10s": dial tcp 10.152.183.130:443: connect: connection refused`

A: If you just installed cert-manager addon, it may still be initializing/downloading images for pods.
For me, the issue resolved itself in a minute or two.
If that doesn't work, try to [completely uninstall cert-manager](https://cert-manager.io/v1.2-docs/installation/uninstall/kubernetes/).

Q: The secret name has 5 alphanumeric characters appended in Kubernetes Dashboard (e.g. `v-herd-eu-ingress-tls-reya6` instead of `v-herd-eu-ingress-tls`)

A: cert-manager is in the process of refreshing that secret. Wait 10 seconds or so; check the pods list for `cm-acme-http-solver`
to find the certbot running. Once certbot is done,
it will rename the secret back to `v-herd-eu-ingress-tls`.
If that doesn't work, cert-manager could be stuck. Try completely uninstalling cert-manager.
You can check the `cert-manager-*` pod for logs.
Alternative is to simply uninstall microk8s via `snap remove --purge microk8s`, then install it back.

Note that cert-manager works with microk8s even when not in ha-cluster mode.

# Getting The Certificates

Cert Manager stores the SSL certificate and private key in the kubernetes secret as a pair of keys: the `tls.crt` and `tls.key`.
To see the SSL certificate from command-line, enter:
```bash
$ microk8s kubectl get secret v-herd-eu-ingress-tls  --namespace v-herd-eu-welcome-page -o jsonpath='{.data.tls\.crt}'|base64 --decode
```
To obtain the private key:
```bash
$ microk8s kubectl get secret v-herd-eu-ingress-tls  --namespace v-herd-eu-welcome-page -o jsonpath='{.data.tls\.key}'|base64 --decode
```

## nginx

If you store those files on a filesystem, you can then feed them for example to an external nginx:
```
server {
	listen 9443 ssl default_server;
	listen [::]:9443 ssl default_server;
	ssl_certificate /etc/nginx/secret/tls.crt;
	ssl_certificate_key /etc/nginx/secret/tls.key;
    location / {
      proxy_pass http://localhost:8080/;
      # proxy_cookie_path / /foo; # use this if you mount your app to `location /foo/`
      proxy_cookie_domain localhost $host;
    }
}
```
You can periodically update the certificates, e.g. once per month. Create a file named `/etc/cron.monthly/nginx-update-tls` with
these contents:
```bash
#!/bin/bash
set -e
microk8s kubectl get secret v-herd-eu-ingress-tls  --namespace v-herd-eu-welcome-page -o jsonpath='{.data.tls\.crt}'|base64 --decode >/etc/nginx/secret/tls.crt
microk8s kubectl get secret v-herd-eu-ingress-tls  --namespace v-herd-eu-welcome-page -o jsonpath='{.data.tls\.key}'|base64 --decode >/etc/nginx/secret/tls.key
systemctl reload nginx
```

Don't forget to `chmod a+x /etc/cron.monthly/nginx-update-tls`.

This way, you can easily expose services, which are running outside kubernetes, yet they will still be protected by https.
The only disadvantage is that they'll run on a different port, in this case 9443.
