---
layout: post
title: Deploy Your Vaadin App To Google Cloud Kubernetes
---

In this setup we'll have a Kubernetes Cluster with a Load-balancer, running
your app from a docker image, connected to a Google Cloud SQL running MySQL.

We will use the [Vaadin-Kotlin-PWA](https://github.com/mvysny/vaadin-kotlin-pwa)
example app in this tutorial.

## Preparation Steps

You will need to create a Google Cloud Project from your [Google Cloud console](https://console.cloud.google.com/).
Simply provide `vok-pwa` as the project name.

### Create SQL Database VM

Go to the `SQL` menu tab and create the Google Cloud SQL Instance, choosing MySQL 5.7.
During the installation, provide this
password to root: `PfJ739VoMMDrs`.

Expand the "Configuration Options / Connectivity", uncheck the "Public IP" and check the "Private IP".
If that cannot be done because of Google APIs not being enabled, simply visit the
`Kubernetes Engine` page and the APIs will be enabled automatically.

Select the Default network for Private IP. Also click `Allocate and connect` button.

Once the VM is created, visit the VM details page and write down the Private IP
Address, e.g. `10.97.16.3`.

Don't forget to create the `vok_pwa` database after the VM is up.

> Note: disabling the "Public IP" will leave the
database inaccessible from your development machine. It's not a problem for the
server since it will use Flyway to bring the database schema up-to-date automatically,
but you will be unable to see the database contents from your dev machine.

### Preparing Local Env
 
You'll need to install the `docker-credential-gcr` tool so that JIB can upload stuff into GCR:
 
1. install the [docker-credential-gcr](https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases)
2. authenticate via `docker-credential-gcr gcr-login`
3. Install gcr into your docker by running `docker-credential-gcr configure-docker`
4. Make sure that Google Cloud Container Registry API is enabled on your project.
5. Define the `GC_PROJECT` environment variable so that it's easier to run the JIB build commands.
   Just set it to your Google Cloud Project ID, e.g. `vok-pwa-256209`.

### Creating Kubernetes Cluster

Head to `Kubernetes Engine / Clusters` and select "Create Cluster". I've selected the
"Your First Cluster" option which creates a simple cluster of 1 node with 1,7GB of RAM,
perfect for experimenting. Use "Location Type" "Zonal", Node pool pool-1 of 1 node
and Machine type `g1-small`.

Once that's done, we need to create a Load Balancer, and for that we need
to have an app deployed. To deploy VOK-PWA to Google Container Registry you first need to create a Docker
image and publish it to GCR:

```bash
./gradlew clean build jib --image=gcr.io/$GC_PROJECT/vok_pwa
```

Once that's done, select your Cluster and click the "Deploy" button.
Select "Existing container image" and select the `vok_pwa/latest` image.
Add the following environment variables:
 
* `VOK_PWA_JDBC_DRIVER` = `com.mysql.jdbc.Driver`
* `VOK_PWA_JDBC_URL` = `jdbc:mysql://MYSQLIP:3306/vok_pwa?useUnicode=true`
* `VOK_PWA_JDBC_USERNAME` = `root`
* `VOK_PWA_JDBC_PASSWORD` = `PfJ739VoMMDrs`

With these env variables we configure the VOK-PWA app to properly connect to
our Google Cloud SQL database.

Replace `MYSQLIP` with the SQL Private IP Address
as above, e.g. `10.97.16.3`. The rest of the Configuration doesn't matter -
select default Namespace, for example "VOK-PWA" as App Name; Labels are not used.
Click the "Deploy" button.

> Note: You can now verify that the node booted up properly, by visiting
`Workloads / VOK-PWA` and clicking the "Container Logs" link.

In the `Workloads` tab, click "VOK-PWA". There will be a warning regarding the
visibility "To let others access your deployment, expose it to create a service " -
follow the warning and create a Load Balancer. Make sure to setup
port forwarding from 80 to 8080. The Load Balancer will be created with a Static IP.

You can check the IP by visiting `Kubernetes Engine / Service & Ingress`
and checking out the link in the "Endpoints" column in the list. 

Now, you can simply browse `http://LOAD_BALANCER_IP:80` and the VOK-PWA app will
be running.

## Updating VOK-PWA in Kubernetes Cluster

To deploy VOK-PWA to Google Container Registry you first need to create a Docker
image and publish it to GCR:

```bash
./gradlew clean build jib --image=gcr.io/$GC_PROJECT/vok_pwa:2
```

Once that's done, go into `Workloads / VOK-PWA / Actions / Rolling update`,
set `gcr.io/vok-pwa/vok_pwa:2` as Image, then click "Update".

## Viewing App Logs

Go to `Kubernetes Engine / Workloads` tab, click "VOK-PWA", then click the
"Container Logs" link.

If there is something wrong with the server and it won't start up properly (e.g.
because of invalid migration, database security issue etc), 

### Troubleshooting

Q: After Load Balancer setup the Workloads says "Does Not Have Minimum Availability"
and "Pod errors: Unschedulable" and "Cannot schedule pods: Insufficient cpu.".

A: Click `Workloads / VOK-PWA / Actions / Autoscale` and set min=1 max=1. Then
   click `Workloads / VOK-PWA / Actions / Scale` and type in "1".

Q: Restart the pods since I forgot to create a database

A: I've found no way to restart pods other than publishing a new image and
Roll-update to it.
