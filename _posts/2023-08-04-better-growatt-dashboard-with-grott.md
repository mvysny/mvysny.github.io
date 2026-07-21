---
layout: post
title: Better Growatt Dashboard with Grott
---

The default Growatt Dashboard is slowly refreshed, often behind the real data by half a hour or more.
The mobile Growatt app is horrible, it frequently requires you to re-login, and then shows
obsolete data. The solution is to grab the data from Growatt Inverter ourselves and visualize them
using [Grafana](https://grafana.com/).

We'll use the following software:

* [Grott](https://github.com/johanmeijer/grott) to capture the data (voltages, watts, temperatures)
  periodically from the Growatt Inverter.
* [InfluxDB2](https://www.influxdata.com/lp/influxdb-database) to store the data
* [Grafana](https://grafana.com/) to visualize the data.

We'll run the software on an Ubuntu box via Docker. First, create a token using the manual at
[renogy-klient](https://github.com/mvysny/renogy-klient/#influxdb-2). We'll use the token as a password
to access InfluxDB2.

## Grott

We'll capture the data by rerouting the traffic from Growatt Inverter to Growatt servers,
as described at [Grott: rerouting the network](https://github.com/johanmeijer/grott/wiki/Rerouting-Growatt-Wifi-TCPIP-data-via-your-Grott-Server).
This approach is simpler than sniffing.

A bit about Grott's configuration. By default, Grott tries to parse the date+time of the data measurement
from the Growatt data packets. However, this method prove to me to produce incorrect results, e.g.
parsing `2023-03-04T19:15:00` as `2023-03-04T09:15:00`, which completely messed up the data. The reason
is really a bad parsing and not a timezone shift (my timezone is GMT+3, so 3 hour difference between UTC and my tz).
Setting the datetime timestamper to "server" (that is, using current server time+date) fixed the issue.
In this mode, Grott captures the date in UTC, regardless of server's timezone setting; using `gtimezone`
would shift the time further by -3 hours, producing incorrect times in InfluxDB2, therefore we won't
use `gtimezone` with the "server" setting.

We'll also disable the MQTT support since [we'll use InfluxDB2](https://github.com/johanmeijer/grott/wiki/InfluxDB-Support).
Please find more information
on [Grott docker image](https://hub.docker.com/r/ledidobe/grott). For all configuration settings
please see [Grott Configuration](https://github.com/johanmeijer/grott/wiki/Grott-Configuration) page.

We need to patch Grott, in order to be able to run in the Docker-Compose environment, see
[Issue #103](https://github.com/johanmeijer/grott/issues/103) for more details.

## InfluxDB2

InfluxDB2 is a datetime-based database - it remembers measurements and keys them by the datetime when they were taken.
We'll use it to store the measurements from the Growatt Inverter. The configuration is quite straightforward
and is described at the [influxdb Docker image documentation](https://hub.docker.com/_/influxdb).

## Grafana

Grafana visualizes data coming from various sources, including InfluxDB2 database.

* [Grafana Docker image](https://hub.docker.com/r/grafana/grafana)
* [Tips on how to run Grafana via Docker](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/)

We'll modify Grafana settings and enable [Anonymous access](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/grafana/#anonymous-authentication),
so that you will not have to enter username/password every time you want to see the dashboard.

## Running Everything

We'll simply run everything in a Docker-Compose environment. Create a folder where the apps will run,
e.g. `/home/user/grott`. Download `https://github.com/johanmeijer/grott/blob/master/grottconf.py` into that
folder and [patch it according to these instructions](https://github.com/johanmeijer/grott/issues/103#issuecomment-1663948264).
Then, create a folder named `db` which will store the database contents.

To store Grafana data, create a folder named `grafana_data`. Run `chmod 0777 grafana_data` to
allow Grafana to write to that folder.

Now, create the following `docker-compose.yaml` file:

```yaml
version: '2'
services:
  grott:
    image: ledidobe/grott:2.8.2
    environment:
      gnomqtt: "true"
      ginflux: "true"
      ginflux2: "true"
      gifip: "influxdb.dc"
      gifport: 8086
      giftoken: "TODO admin token"
      giforg: "my_org"
      gifbucket: "grott"
      gtime: "server"
    ports:
      - "5279:5279"
    volumes:
      - "./grottconf.py:/app/grottconf.py"
    restart: unless-stopped
  influxdb.dc:
    image: influxdb:2.7.1
    restart: unless-stopped
    volumes:
      - "./db:/var/lib/influxdb2"
    ports:
      - "8086:8086"
    environment:
      DOCKER_INFLUXDB_INIT_MODE: "setup"
      DOCKER_INFLUXDB_INIT_USERNAME: "admin"
      DOCKER_INFLUXDB_INIT_PASSWORD: "mypassword"
      DOCKER_INFLUXDB_INIT_ORG: "my_org"
      DOCKER_INFLUXDB_INIT_BUCKET: "grott"
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: "TODO admin token"
  grafana:
    image: grafana/grafana:latest-ubuntu
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - "./grafana_data:/var/lib/grafana"
    environment:
      GF_AUTH_ANONYMOUS_ENABLED: "true"
      GF_AUTH_ANONYMOUS_ORG_NAME: "Main Org."
      GF_AUTH_ANONYMOUS_HIDE_VERSION: "true"
```

To run everything, simply run:

```bash
$ docker-compose up
```

You can navigate to [localhost:8086](http://localhost:8086) to see the InfluxDB2
admin interface; use `admin`/`mypassword` to log in. Also see the console output
for Grott: it either starts properly, or fails to start and will restart endlessly.

## Hooking it up with Growatt

Make sure Growatt Inverter is connected to the internet and can see your server - for example
they're both on the same LAN. Assign a permanent IP address to your ubuntu machine, say 192.168.1.2.
Now you need to configure Growatt Inverter to communicate via Grott.

That can be achieved from [server.growatt.com](https://server.growatt.com). Login. Then:
- On the first tab "Dashboard", scroll down to "My photovoltaic devices". Click "All Devices" on the right, and you
should see your Data Logger.
- Click "Data Logger Settings", agree and click "Yes". This will open a dialog with advanced data logger settings.
- Select the "Set Ip (Caution ...)" command and fill in the IP of your server, say 192.168.1.2
- Below there's "Enter Key To Save". The key is "growatt" plus the current date in the yyyymmdd format, e.g.
  `growatt20230804`.
- Hit the `Yes` button - the settings will be saved to your Data Logger.

After a couple of seconds, Grott will spring into life and will log a lot of activity into the console,
as the communication between the Data Logger and Growatt servers now pass through Grott.
After 1-5 minutes, a first entry should be created in the InfluxDB2 database. Time to configure Grafana!

## Grafana Revisited

Navigate to [localhost:3000](http://localhost:3000). Since anonymous access is enabled, you'll
see the welcome screen. Login via the link in the upper-right corner. The
default username/password is `admin`/`admin`, change the password but leave the default
organization as "Main Org." since it's referred to via the anonymous access above.

Let's create a connection to the InfluxDB database. Navigate to *Connections / Add new connection / InfluxDB*,
then *Create a InfluxDB data source*:
- Select "Flux" as the query language
- URL is `http://influxdb.dc:8086`
- Uncheck Basic Auth
- Organization: my_org
- Token: The InfluxDB admin token from above
- Default Bucket: grott

Press *Save & Test* - the connection is tested, it should succeed and the data connection is now saved.

> Tip: you can start Grafana from a separate docker-compose; you then need to
> [register `host.docker.internal`](https://stackoverflow.com/questions/31324981/how-to-access-host-port-from-docker-container)
> as a DNS for the host machine, then change the URL to `http://host.docker.internal:8086`.
