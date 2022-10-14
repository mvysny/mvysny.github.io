---
layout: post
title: Quickly connect to PostgreSQL In Docker
---

The [postgresql docker docs](https://hub.docker.com/_/postgres) are pretty good. For experimenting, run

```bash
$ docker run -it --rm -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 postgres
```

To connect to it from your machine, first install the client:

```bash
$ sudo apt install postgresql-client-14
```

Then run this to connect to it with the `psql` command-line client:

```bash
$ PGPASSWORD=mysecretpassword psql -h localhost -p 5432 -U postgres postgres
```

You can also run SQL commands from the command line:

```bash
$ PGPASSWORD=mysecretpassword psql -h localhost -p 5432 -U postgres postgres -c "CREATE TABLE IF NOT EXISTS foo (id bigint primary key not null)"
$ PGPASSWORD=mysecretpassword psql -h localhost -p 5432 -U postgres postgres -c "INSERT INTO foo (id) VALUES (1)"
$ PGPASSWORD=mysecretpassword psql -h localhost -p 5432 -U postgres postgres -c "SELECT * FROM foo"
```
