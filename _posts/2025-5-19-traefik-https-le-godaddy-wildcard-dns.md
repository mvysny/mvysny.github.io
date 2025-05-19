---
layout: post
title: Setup wildcard DNS https certificates on Traefik with GoDaddy and Let's Encrypt
---

It's possible to set up your DNS record to handle wildcard requests, so that you can
host your apps using Traefik at `http://anything.yourdomain.com`. For this to work, we will
enable proper wildcard support on your DNS configuration, and we will
configure Traefik's Let's Encrypt integration for a proper wildcard support

In order to obtain a https certificate for a wildcard DNS, we'll let Traefik use
Let's Encrypt [DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)
type when verifying wildcard DNS. In short, the ACME client needs to briefly add a specific TXT record to your DNS entry.
In order to do that, the ACME client needs to talk to GoDaddy via GoDaddy's public API, and temporarily modify the DNS record.
Traefik will use its [dnsChallenge](https://doc.traefik.io/traefik/https/acme/#dnschallenge) ACME client;
we'll configure Traefik to talk to GoDaddy.

Traefik's documentation is a bit tricky to go through, but once you understand the basic idea,
things are pretty simple:

1. In Traefik, you create a "Certificate Resolver" which is able to talk to Let's Encrypt and obtain the certificate.
2. Certificate Resolver needs to add a temporary TXT record to your DNS, as a part of the DNS-01 challenge protocol.
   It needs access to GoDaddy's API in order to achieve that.
3. In order to know the list of DNS to obtain the certificate for, Certificate Resolver goes through
   all routes you configure in Traefik, checks their `Host` rules or other meta-data, and from
   that builds a list of DNS domains to resolve the certificate for.

To go through this tutorial, set up two Vaadin apps as per [2 Vaadin Apps 1 Traefik](../2-vaadin-apps-1-traefik/).

## GoDaddy

In this example we'll use GoDaddy. First, we need GoDaddy's API Keys to communicate with GoDaddy's API.
Go to [GoDaddy Developer Portal](https://developer.godaddy.com) and create an API key, for the
"Production" environment. You'll get a pair of values, a Key and a Secret. We'll pass those to Traefik
via environment variables: write those values down to a file named `.provider.env`:
```
GODADDY_API_KEY=xyz
GODADDY_API_SECRET=xyz
```

Now enable wildcard support with your DNS provider.  Go to [GoDaddy](https://godaddy.com) & login,
click on your domain, then "Manage Domain", the "DNS" tab, then "Add New Record":

* Type: A, Name: `*` (an asterisk), Data: the IP address of your server.
* Also make sure that there's another Type:A record named `@`, with the IP address of your server.

Hit save - the change will eventually propagate through all DNS servers and you'll be able to `ping foo.yourdomain.com`.

## Traefik

We'll configure the Certificate Resolver in Traefik: modify the `docker-compose.yaml`
file as follows:

```yaml
version: '3'

networks:
  web:
    external: true

services:
  traefik:
    # The official v3 Traefik docker image
    image: traefik:v3.3.5
    command:
      # Enables the web UI and tells Traefik to listen to docker
      - --api.insecure=true
      - --providers.docker
      # Enables https :443 entrypoint
      - --entrypoints.https.address=:443
      - --certificatesResolvers.yourdomain_com_godaddy.acme.dnsChallenge.provider=godaddy
      # Email address used for registration.
      - --certificatesresolvers.yourdomain_com_godaddy.acme.email=your@email
      # Certificates storage
      - --certificatesresolvers.yourdomain_com_godaddy.acme.storage=/tls-certificates/acme.json
    env_file:
      - .provider.env
      # .provider.env contains `GODADDY_API_KEY` and `GODADDY_API_SECRET`.
      # These variables are used by Traefik to talk to GoDaddy API
    networks:
      - web
    ports:
      # The HTTP port
      #- "80:80"
      # The Web UI (enabled by --api.insecure=true)
      - "8080:8080"
      - "443:443"
    volumes:
      # So that Traefik can listen to the Docker events
      - /var/run/docker.sock:/var/run/docker.sock
      - ./tls-certificates:/tls-certificates
```

This configures a new Certificate Resolved named "yourdomain_com_godaddy" which
will download the certificates from Let's Encrypt.

> NOTE: The "your@email" above should match the contact you listed in your DNS domain at GoDaddy,
> but I don't think this is a hard requirement - it's probably Let's Encrypt who wants to have
> some kind of contact.

Create a folder named `tls-certificates` - Traefik will store all private keys & certificates
obtained from Let's Encrypt to `tls-certificates/acme.json`.

Don't restart Traefik Docker just yet - we need to configure the apps as well.

## Configuring Apps

Modify the `vaadin-boot-example-gradle.docker-compose.yml` as follows:
```yaml
version: '3'

networks:
  web:
    external: true
services:
  vaadin-boot-example-gradle:
    image: test/vaadin-boot-example-gradle:latest
    networks:
      - web
    labels:
      - "traefik.http.routers.vaadin-boot-example-gradle.entrypoints=https"
      - "traefik.http.routers.vaadin-boot-example-gradle.rule=Host(`app1.yourdomain.com`)"
      - "traefik.http.routers.vaadin-boot-example-gradle.tls=true"
      - "traefik.http.routers.vaadin-boot-example-gradle.tls.certresolver=yourdomain_com_godaddy"
      - "traefik.http.routers.vaadin-boot-example-gradle.tls.domains[0].main=yourdomain.com"
      - "traefik.http.routers.vaadin-boot-example-gradle.tls.domains[0].sans=*.yourdomain.com"
```

From this configuration, yourdomain_com_godaddy will know to retrieve the https certificate for
`yourdomain.com` and `*.yourdomain.com` and use it for this particular route.
See [Traefik: Domain Definition](https://doc.traefik.io/traefik/https/acme/#domain-definition)
for more information.

## Restart

Restart both Traefik and app Docker container. You may need to completely kill and remove
the containers in order for the new labels to take effect - you can use `docker-compose rm`
for that.

If you did everything right, traefik should now start listening on https 443.
You can browse to `http://yourdomain.com:8080` - that's the Traefik monitoring UI which
should show that there's the https entrypoint on port 443, and there's a route to your app.

If you browse to your app at `https://app1.yourdomain.com`, you'll probably get a certificate warning in your browser:
this is okay. Traefik will use a self-signed certificate until it is able to obtain a proper
certificate from Let's Encrypt. Going through the DNS-01 procedure can take about a minute or two,
so be patient and observe Traefik logs - it will print an error log if anything goes wrong.

## Additional links

Here's an example of [GoDaddy integration](https://stackoverflow.com/questions/61234489/cannot-get-wildcard-certificate-with-traefik-v2-and-godaddy).
