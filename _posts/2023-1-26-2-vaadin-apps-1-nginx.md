---
layout: post
title: 2 Vaadin Apps 1 Nginx
---

The goal is to setup 2 Vaadin apps on one Ubuntu machine:

* 2 Vaadin apps are running in production mode in docker
* Configure nginx as 'reverse proxy' so that the apps are accessible via http://myserver.fake/app1 and http://myserver.fake/app2,
  but also http://vaadin1.fake and http://vaadin2.fake
* We'll make sure that the session cookies are changed properly, so that both apps are accessible at the same time.

## Setup

I assume that docker is installed & configured on your machine. To install nginx, run:

```bash
sudo apt install nginx
```

Now browse to [localhost](http://localhost) and check that you can see the "Welcome to nginx!" welcome message.
The file is served from `/var/www/html/index.nginx-debian.html` via the rule present in the `/etc/nginx/sites-enabled/default` file.

We'll run two Vaadin apps from docker: [vaadin-boot-example-gradle](https://github.com/mvysny/vaadin-boot-example-gradle)
and [beverage-buddy-vok](https://github.com/mvysny/beverage-buddy-vok). Run the following in your terminal:

```bash
git clone https://github.com/mvysny/vaadin-boot-example-gradle
cd vaadin-boot-example-gradle
docker build --no-cache -t test/vaadin-boot-example-gradle:latest .
docker run --rm -ti -p127.0.0.1:30000:8080 test/vaadin-boot-example-gradle
```
and
```bash
git clone https://github.com/mvysny/beverage-buddy-vok
cd beverage-buddy-vok
docker build --no-cache -t test/beverage-buddy-vok:latest .
docker run --rm -ti -p127.0.0.1:30001:8080 test/beverage-buddy-vok
```
Verify that you can access those apps: [localhost:30000](http://localhost:30000) and [localhost:30001](http://localhost:30001).

Notice something strange when you open both at the same time in two tabs: clicking into first app will make the other
one reload and vice versa. The problem is the session cookie which identifies the session:
it is bound to localhost host and `/` path but not to a port, and therefore the apps keep overwriting
each other session cookies. You can see that for yourself, by opening dev tools in your Firefox via `F12`,
then 'Storage' tab, 'Cookies' and the `JSESSIONID` cookie. Notice how the value changes when you start
interacting with the other app.

We will fix that in nginx.

## Faking the DNS addresses

Edit `/etc/hosts` and add the following line to the end:
```bash
127.0.0.1 myserver.fake vaadin1.fake vaadin2.fake
```
Now when browsing to `http://myserver.fake`, the browser will report the hostname as `myserver.fake`,
exactly as if the DNS name was provided by an actual DNS server. We can take advantage of this,
to test as if on a real environment.

## nginx reverse proxy

[Nginx](https://www.nginx.com/) (pronounced Engine-X) is a web server offering lots of features.
We'll use the 'reverse proxy' feature, which forwards all requests made to http://myserver.fake/app1
to http://localhost:30000, then modify the response html (rewrites links and paths for example),
so that the browser thinks it came from http://myserver.fake/app1

Nginx is configured via the `/etc/nginx/nginx.conf` file, which includes `/etc/nginx/sites-enabled/*` and
`/etc/nginx/conf.d/*.conf`. Let's create `/etc/nginx/conf.d/vaadin.conf` with the following contents:

```
server {
  server_name myserver.fake;
  location /app1/ {
    proxy_pass http://localhost:30000/;
    proxy_cookie_path / /app1/;
    proxy_cookie_domain localhost $host;
  }
}
```

Restart nginx via `sudo systemctl reload nginx.service` and the first Vaadin app now runs
at [myserver.fake/app1](http://myserver.fake/app1).

Note the `proxy_cookie_path` and `proxy_cookie_domain`. Since the request to the Vaadin app
comes from the nginx from localhost, Vaadin thinks that the path is `/` and the host is `localhost`
and would produce such JSESSIONID cookie. The cookie would then be ignored by the browser (since
the request went to `myserver.fake/app1`), which would mean that a new session would
constantly get created. Try removing the `proxy_*` settings temporarily for yourself, to see
the outcome.

We're now ready to prepare the final configuration file:

```
server {
  server_name myserver.fake;
  location /app1/ {
    proxy_pass http://localhost:30000/;
    proxy_cookie_path / /app1/;
    proxy_cookie_domain localhost $host;
  }
  location /app2/ {
    proxy_pass http://localhost:30001/;
    proxy_cookie_path / /app2/;
    proxy_cookie_domain localhost $host;
  }
}
server {
  server_name vaadin1.fake;
  location / {
    proxy_pass http://localhost:30000/;
    proxy_cookie_domain localhost $host;
  }
}
server {
  server_name vaadin2.fake;
  location / {
    proxy_pass http://localhost:30001/;
    proxy_cookie_domain localhost $host;
  }
}
```

Now try all of the following links:

* [myserver.fake/app1](http://myserver.fake/app1)
* [myserver.fake/app2](http://myserver.fake/app2)
* [vaadin1.fake](http://vaadin1.fake/)
* [vaadin2.fake](http://vaadin2.fake/)

## https via Let's Encrypt

To enable https with Let's Encrypt, you obviously have to set up nginx on an actual
server running somewhere in the internet; then you have to register a bunch of domains
and make them point to the IP address where the server is running.

Use Let's Encrypt and follow [Certbot instructions](https://certbot.eff.org/instructions?ws=nginx&os=ubuntufocal).
The `sudo certbot --nginx` command will modify all active nginx configuration files
referenced from `/etc/nginx/nginx.conf`: it will enable https, will download certificates and store them locally,
and set up periodic refresh of the certificates.

You do not have to have any account at Let's Encrypt: the only requirement is to own the DNS domain and
to have it pointing to the server's IP.

## What's next

Now that you understand how this basic setup works, we'll do the same setup, but with Kubernetes. Stay tuned.
