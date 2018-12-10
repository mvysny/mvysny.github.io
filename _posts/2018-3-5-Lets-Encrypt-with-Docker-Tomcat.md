---
layout: post
title: Let's Encrypt with Docker Tomcat
---

In the previous blog post [we've used self-signed certificate with Docker Tomcat](http://mavi.logdown.com/posts/6675210). However, in order to have a properly protected web site, we need to use a proper set of certificates. We'll use the Let's Encrypt authority to obtain the keys at no cost.

# Preparing the server and DNS

First, create a virtual server running Ubuntu 17.10, then make sure you can SSH into that box or you can at least launch a console via the cloud vendor web page. Write down the server IP.

Second, register a DNS domain, for example at [GoDaddy](https://uk.godaddy.com/). I'll register `your-page.eu` but you're free to register whatever domain you see fit. You will then need to edit the DNS records for that domain, and make sure that `A` record points to your server's IP.

# Obtaining SSL certificates from Let's Encrypt

Now let's obtain the certificates from [Let's Encrypt](https://letsencrypt.org/). The easiest way is to use Certbot which comes pre-packaged in Ubuntu 17.10. Run the following in your box terminal:

```bash
sudo apt install certbot
certbot certonly
```

Certbot is going to ask you a couple of questions. I tend to prefer to use the standalone mode (the certbot takes over port 80 and does everything on its own; this collides with Tomcat listening on 80 but since we need to stop Tomcat to renew the certificates anyway this is perfectly fine). Then just make sure to pass in both `your-page.eu` and `www.your-page.eu` so that both domains are SSL-protected.

When Certbot finishes, you'll be able to find the certificate files at `/etc/letsencrypt/live/your-page.eu`. We will now register the certificates into Tomcat.

# Running dockerized Tomcat with the certificates

Let's deploy your app in a way that everything can be started using the `docker-compose up -d` command. The easiest way is to create a directory named `/root/app/` and place the following `docker-compose.yml` file there:

```
version: '2'
services:
  web:
    image: tomcat:9.0.5-jre8
    ports:
      - "80:8080"
      - "443:8443"
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt
      - ./server.xml:/usr/local/tomcat/conf/server.xml
```

 > **Note:** we need to map the entire `/etc/letsencrypt` into the Docker container; just mapping the `/etc/letsencrypt/live/your-page.eu` folder alone is not enough since those `pem` files are symlinks which would stop working in Docker and Tomcat would fail with `FileNotFoundException`.

Feel free to use the `server.xml` from the [self-signed openssl](http://mavi.logdown.com/) article, but change the appropriate connector part to:
```xml
   <Connector port="8443" protocol="org.apache.coyote.http11.Http11AprProtocol"
              maxThreads="150" SSLEnabled="true" >
	   <UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />
		 <SSLHostConfig>
       <Certificate certificateKeyFile="/etc/letsencrypt/live/your-page.eu/privkey.pem"
                    certificateFile="/etc/letsencrypt/live/aedict-online.eu/cert.pem"
                    certificateChainFile="/etc/letsencrypt/live/aedict-online.eu/chain.pem"
                    type="RSA" />
			</SSLHostConfig>
	</Connector>
```

Store the `server.xml` into `/root/app/`.

Now go into `/root/app` and try to run the Tomcat server:

```bash
cd /root/app
docker-compose up
```

The `pem`s are not password-protected so it should work.

> **Note:** if Tomcat stops on `Deploying web application directory` and seems to do nothing, it may have ran out of entropy. You can verify this by running `cat /proc/sys/kernel/random/entropy_avail` - if this prints anything less than 100-200 then just run `apt install haveged` to help building up the entropy pool. Tomcat will take 2 minutes to start at first, but when the entropy is high, further starts will be much quicker. You can read more at [Tomcat Hangs](https://serverfault.com/questions/655616/tomcat7-hangs-on-deploying-apps).

Now you can visit https://your-page.eu and you should see the Tomcat welcome page protected by https. Good job!

You can also verify at [https://www.digicert.com/help/](https://www.digicert.com/help/) that your SSL certificate is working properly.

# Auto-renewing certificates

Let's Encrypt certificates only last for 90 days. Luckily the certificates can be renewed when they are older than 60 days, which gives us some time to do the renewal process. The certificates can be updated automatically using the Certbot. The Certbot can run hook scripts before and after the renewal happens, so that:

* we can stop Tomcat in order for the Certbot to take over the port 80,
* we can start Tomcat to reload certificates when the new certificates are in place

Let's create two scripts: `/root/start_server`:
```bash
#!/bin/bash
set -e -o pipefail

date
cd /root/app
docker-compose up -d
```

`/root/stop_server`:
```bash
#!/bin/bash
set -e -o pipefail

date
cd /root/app
docker-compose down
```

Luckily `docker-compose down` will block until all containers are stopped, and it will unbind from port 80 prior terminating, which gives room for Certbot's own server.

To run the renewal process automatically, run
```
crontab -e
```
and add the following line:
```
30 2 * * 1 certbot renew --pre-hook "/root/stop_server" --post-hook "/root/start_server" >> /var/log/le-renew.log
```

That will make Certbot to check for new certificates every week at night. Certbot will do nothing if the certificates do not need to be renewed (since they're younger than 60 days). If the certificates need to be renewed (they are older than 60 days) it will stop the Tomcat server, update the certificates and then start the Tomcat server.

That's it.
