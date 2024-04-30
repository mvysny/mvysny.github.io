---
layout: post
title: Jenkins Behind Reverse Proxy Nginx
---

Say you want to expose Jenkins at `/jenkins` via nginx (which also unwraps https).
You try to define the standard `proxy_pass http://localhost:8080/;` rule, and nothing works.

```
location /jenkins/ {
    proxy_pass http://localhost:8080/;
}
```
And all hell breaks loose - Jenkins redirects to `/login` which causes Nginx to return 404.
Even if you navigate to `/jenkins/login`, all CSS are missing and everything looks completely broken.

The reason is that Jenkins uses absolute paths to link to css, js and other stuff, and
[Nginx doesn't support absolute paths](https://stackoverflow.com/questions/30350185/nginx-reverse-proxy-configuration-to-handle-absolute-paths).
The obvious solution is to fiddle with `sub_filter` and rewrite paths in Jenkins html from `/static/*` to `/jenkins/static`,
and it kinda works:

```
location /jenkins/ {
    rewrite ^(/jenkins)$ $1/ permanent;
    sub_filter_types *;
    proxy_set_header Accept-Encoding ""; # disable jenkins http compression!!!! Otherwise sub_filter silently won't work
    sub_filter 'href="/' 'href="/jenkins/';
    sub_filter "src='/" "src='/jenkins/";
    sub_filter 'src="/' 'src="/jenkins/';
    sub_filter_once off;
    proxy_pass http://localhost:8080/;
    proxy_cookie_path / /jenkins; # use this if you mount your app to `location /foo/`
    proxy_cookie_domain localhost $host;
}
```

> Note: make sure Nginx supports sub_filters: run `nginx -V` and check it contains `--with-http_sub_module`

But the proper solution is to force Jenkins to use the `/jenkins` context root.

## Proper solution

Run `systemctl edit jenkins` and edit the file to look like this:
```
[Service]
Environment="JENKINS_LISTEN_ADDRESS=127.0.0.1"
Environment="JENKINS_PREFIX=/jenkins"
```
Save, then restart Jenkins.

Now, the rewrite rule in Nginx is simplified:
```
location /jenkins/ {
    proxy_pass http://localhost:8080;
}
```
