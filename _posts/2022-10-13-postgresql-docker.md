---
layout: post
title: Quickly connect to PostgreSQL In Docker
---

The [postgresql docker docs](https://hub.docker.com/_/postgres) are pretty good. For experimenting, you
can run PostgreSQL in a docker container. Note that once you hit CTRL+C, the database is gone:

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

or (but this will make the password visible in the list of processes, see [interactive password](https://stackoverflow.com/questions/6405127/how-do-i-specify-a-password-to-psql-non-interactively))

```bash
$ psql postgresql://postgres:mysecretpassword@localhost:5432/postgres
```

You can also run SQL commands from the command line:

```bash
$ PGPASSWORD=mysecretpassword psql -h localhost -p 5432 -U postgres postgres -c "CREATE TABLE IF NOT EXISTS foo (id bigint primary key not null)"
$ PGPASSWORD=mysecretpassword psql -h localhost -p 5432 -U postgres postgres -c "INSERT INTO foo (id) VALUES (1)"
$ PGPASSWORD=mysecretpassword psql -h localhost -p 5432 -U postgres postgres -c "SELECT * FROM foo"
```

## Installing PostgreSQL server on Ubuntu

Run the following to install PostgreSQL, configure user and create the database:
```bash
sudo apt install postgresql
sudo -u postgres psql
postgres=# create database mydb;
postgres=# create user myuser with encrypted password 'mypass';
postgres=# grant all privileges on database mydb to myuser;
```

PostgreSQL will by default listen on localhost:5432. Then, to connect to the database:

```bash
$ psql postgresql://myuser:mypass@localhost:5432/mydb
```
