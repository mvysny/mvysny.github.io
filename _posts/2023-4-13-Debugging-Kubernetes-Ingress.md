---
layout: post
title: Debugging Kubernetes Ingress
---

If Kubernetes Ingress routing controller is misconfigured, it can provide surprising
results. This guide lists all the points to take a look at. Works with [Microk8s](https://microk8s.io/)
but should apply to any Kubernetes system.

## Check out ingress controller logs

The Ingress controller is running as a `nginx-ingress-microk8s-controller` Daemon set, in the
`ingress` namespace.

### Via the Dashboard

Run the dashboard via `microk8s dashboard-proxy` and navigate to
[https://localhost:10443](https://localhost:10443) to open the Dashboard.
Then, select the "ingress" namespace and navigate to "pods", there should be one pod
named `nginx-ingress-microk8s-controller-*`. View its logs - all routing actions will be
logged there.

Example of the routing log line:

```
10.1.34.1 - - [13/Apr/2023:06:23:07 +0000] "GET / HTTP/1.1" 200 817 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" 3680 0.001 [v-herd-eu-welcome-page-service-80] [] 10.1.34.39:80 817 0.000 200 1d1d0eedc138e8209c6f1d7af7dc5662
```

* `10.1.34.1` is the ingress controller internal cluster IP
* `"GET / HTTP/1.1"` is the request it received from the browser
* `200` is the response code, in this case `200 HTTP OK`.
* `v-herd-eu-welcome-page-service-80` is the service to which the request was redirected to.
* `10.1.34.39:80` is the IP+port address of the service to which the request was redirected to.

This line shows that the routing was successful and the request was routed to the correct service.
If the request is routed to an incorrect service (or if the request fails because the service is down or doesn't respond or the port is incorrect),
you will be able to spot that easily in the log line.

### Via command-line

You can obtain the logs using the command-line access too. First, figure out the exact name of the ingress pod:

```bash
$ mkctl get pods --namespace ingress
NAME                                      READY   STATUS    RESTARTS      AGE
nginx-ingress-microk8s-controller-txgf2   1/1     Running   3 (14m ago)   21h
```

Then, check the logs

```bash
$ mkctl logs -f nginx-ingress-microk8s-controller-txgf2 --namespace ingress
...
10.1.34.1 - - [13/Apr/2023:06:23:07 +0000] "GET / HTTP/1.1" 200 817 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" 3680 0.001 [v-herd-eu-welcome-page-service-80] [] 10.1.34.39:80 817 0.000 200 1d1d0eedc138e8209c6f1d7af7dc5662
```

The `-f` will cause the command to follow the logs and print new log lines immediately as they're logged.
