---
layout: post
title: Why I Tend To Avoid MySQL
---

A summary of reasons why I tend to avoid MySQL (or MariaDB for that matter) and use PostgreSQL instead:

> Don't get me wrong - MySQL is a highly performant database. It just has those
ridiculous "features" which cause you to share a lot of intimate wtf moments.

## 1. `utf8` replaces certain characters with `?`

[Have you ever wondered why MySQL replaces certain characters with `?` even when you're
using `utf8`?](https://stackoverflow.com/questions/38363566/trouble-with-utf-8-characters-what-i-see-is-not-what-i-stored)

Yes. In MySQL world, `utf8` is *not* a full-blown Unicode character set, and thus
it can't represent all Unicode characters. It's an alias for `utf8mb3` which simply throws away  
certain characters as unsupported, for optimization reasons. Thankfully, [MySQL is deprecating `utf8mb3`](https://dev.mysql.com/doc/refman/8.0/en/charset-unicode-sets.html)
and will use `utf8mb4` which is able to represent all Unicode characters.

Premature optimization. Rating: 3 out of 3 facepalms, since it causes a lot of wtf moments
for no apparent reason.

## 2. table name case-sensitive, but not on Windows

[Database and table names are not case sensitive in Windows, and case sensitive in most varieties of Unix](https://stackoverflow.com/questions/6134006/are-table-names-in-mysql-case-sensitive)

Rating: 3 out of 3 facepalms, just because it's so fucking ridiculous.

## 3. fulltext index randomly finds nothing

Imagine that you have a unique index U on `owner_id` and `name`, and an index I1 on `owner_id`
and a full-text index I2 on `name`.
 
Running `SELECT * FROM foo where owner_id=3 and MATCH(name) against ('foo')`
will *RANDOMLY* match nothing and return nothing. That's because
MySQL will randomly use the unique index U instead of a combination of I1 and I2, which
is extremely hard to figure out. See [MySQL sporadic MATCH AGAINST behaviour with unique index](https://stackoverflow.com/questions/45281641/mysql-sporadic-match-against-behaviour-with-unique-index)
for more details.

Random behavior changes. Rating: 3 out of 3 facepalms. 

## 4. DDLs do not run in a transaction

The DDLs do not run in a transaction, can not be rolled back and therefore can not
be considered atomic. If you use a
database migration tool such as FlyWay and the DDL fails, FlyWay will have no way
of knowing how many of the DDLs in the script actually passed, and it will
mark that particular migration as failed and you will have to [repair](https://flywaydb.org/documentation/faq.html#repair)
it manually.

Alternatively, [you can have one DDL per file](https://flywaydb.org/documentation/faq.html#rollback)
(which is annoying) and then somehow tell FlyWay to not to mark failed DDLs as failed migration (since
now the migrations are atomic).

Rating: 1 out of 3 facepalms, since running DDL in a transaction is quite hard
to implement and only a handful of databases support this (PostgreSQL does).

## 5. Need to clean up FK in a separate transaction

There is no other sane way to [delete all rows from a self-referential table](https://stackoverflow.com/questions/615797/what-is-the-best-way-to-empty-a-self-referential-mysql-table)
other than running two statements:

```sql
UPDATE 'recursive' SET 'parent_id' = NULL WHERE 'parent_id' IS NOT NULL;
DELETE FROM 'recursive';
```

Rating: 3 out of 3 facepalms + 1 additional facepalm because of having to run those two
statements in a separate transaction, risking database corruption in case the DELETE
fails.

## 6. Unicode not enabled by default

latin1 as the default charset; need to specify
`CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci` for every table create DDL;
need to specify `characterEncoding=UTF-8` to the JDBC driver (`useUnicode=true` is not enough)
to even transfer unicode characters properly to the MySQL server.

2 out of 3 facepalms + 1 facepalm for `useUnicode=true` not working.

## 7. It takes forever to start in Docker

It takes some 30 seconds to start MySQL, as opposed to PostgreSQL, which starts in
2-3 seconds.

3 out of 3 facepalms, since MySQL is clearly inferior to PostgreSQL.
