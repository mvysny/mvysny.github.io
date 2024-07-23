---
layout: post
title: MySQL Docker QuickStart
---

Because we all need to go to the toilet sometimes.

To run the database, with the following things pre-created:

* user: `root`/`my-secret-pw`
* user: `dude`/`my-secret-pw`, all access to the database "mydb"
* database `mydb`

```bash
$ docker run --rm -ti -e MYSQL_ROOT_PASSWORD=my-secret-pw -e MYSQL_DATABASE=mydb -e MYSQL_USER=dude -e MYSQL_PASSWORD=my-secret-pw -p 3306:3306 mysql:8
```

Connect to the database from command-line:

```bash
$ mysql -u dude -p'my-secret-pw' -h 127.0.0.1 -P 3306 -D mydb
```

> Note: use IP address; if you try `-h localhost` then retarded MySQL client will fail with
> ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock'

To import a database dump:
```bash
$ mysql -u dude -p'my-secret-pw' -h 127.0.0.1 -P 3306 -D mydb <dump.sql
```

JDBC URL: `jdbc:mysql://localhost:3306/mydb`

More info at [MySQL at Docker Hub](https://hub.docker.com/_/mysql/).
