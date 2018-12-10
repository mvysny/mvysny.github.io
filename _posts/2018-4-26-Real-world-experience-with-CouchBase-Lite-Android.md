---
layout: post
title: Real-world experience with CouchBase Lite Android
---

I'd like to write something positive, but I can't - my experiences with CouchBase had been highly negative. I'd even dare to say it's an unfinished piece of junk; if you need to setup a syncing platform from your Android app, avoid CouchBase like a plague.

At first everything was peachy, the synchronizers worked correctly and things were synced to the server. Then everything went south.

I've noticed that CouchBase Server [permanently uses 100% of one CPU core](https://github.com/couchbase/goxdcr/issues/4). It has been explained that it's because it gathers statistics in the background. Apparently gathering statistics of an empty bucket (0 documents) is highly time-consuming in CouchBase world. That should be a warning sign of the quality (or rather, the lack thereof) of the whole CouchBase offering. That, combined with a constant stream of poor excuses from the devs for every bug I've opened. I should've abandon the CouchBase stack, but it seemed to be working so far, so I thought I'm simply doing something wrong.

Then things started to break.

# One does not simply use CouchBase server from Docker Compose

At some point the CouchBase Server database grew large enough (well not really that large, 2 million documents is not a big database) so that it started to take 2 minutes to start the Server. However, CouchBase Sync Gateway apparently [is short-tempered](https://github.com/couchbase/sync_gateway/issues/2465) and gives up after a minute or so, simply terminating. That makes it impossible to launch a CouchBase Gateway from docker compose, simply by calling `docker-compose up` since Gateway will die.

I had to write a script which starts the CouchBase server, then sleeps for a minute and then starts the Gateway. Dumb.

# NoSQL running on a SQL?

I was worried about the performance on Android, since CouchBase Lite uses `sqlite` as a backing storage on Android. Brilliant - NoSQL database running on top of SQL, which combines the slowness of the SQL with zero ACID guarantees of the NoSQL! However, it was promised that the Forest DB would perform [2x to 5x faster](https://blog.couchbase.com/mobile-1-2-enable-forestdb/) and thus I gave it a try. It was not a good idea.

Apparently ForestDB is not finished or is flaky or broken, since it gave weird results on the old map/reduce queries for list keys. You know - you search for all keys of type `List` with first item equal to 1 and you'll get lists starting with 2, 0 and others. I couldn't even reproduce those issues since they happened randomly. Also, I could mention the docs which were totally unclear as what will actually be selected, but I can't - CouchBase Lite documentation got rewritten and apparently now every query should use SELECT-like queries, brilliant! Talk about backward compatibility.

To test for flaky query API I've decided to write tests for those views. A bad idea.

# When One close() Fails

I've written simple JUnit tests which opened a database, did a bunch of writes/reads and then closed the database. I noticed that those tests ran pretty slowly; the culprit was the database closer which took like 30 seconds to close the underlying ForestDB database. Upon closer examination I was surprised to find that the native call to DB close actually failed. A brilliant solution was devised - if the DB close fails, repeat. And repeat. And repeat. If it keeps failing, [try at most a hundred times](https://github.com/couchbase/couchbase-lite-java-core/issues/1556), then consider the database closed. Who in the name of God would consider this a good idea?

Anyway, from the point of view of CouchBase Lite devs everything is fine now because *they've dropped ForestDB* and no longer support it in their offerings. So I'm stuck with half-assed junk which is no longer supported and will never be fixed, and can't even migrate to the sqlite backend. Brilliant.

# https, https everywhere!

Securing CouchBase Gateway is simple - just turn on the https in the Gateway config and provide a DNS name. What the docs won't tell you is that by doing that, CouchBase Gateway will reject all requests which do not target that particular DNS name. You no longer can access the Gateway using `localhost`, an IP address, a docker compose alias from within the docker container - you *must* use the DNS name. And sometimes you can't.

In a moment of blissful ignorance I've decided to upgrade Ubuntu 16.04 to 16.10 on Leaseweb. A bad idea - the networking stack got borked in some incomprehensible way that the Gateway client app running on that very machine in docker couldn't access the Gateway through the DNS name. The connection would simply be rejected for no apparent reason. I failed to find the reason, and after I complained, Leaseweb offered to look into the issue (no promise of solving the issue, they would just look) for a mere $100 per hour.

So there I was - the software stack crumbled and my app was unable to connect to the Gateway.

# The Sync No Longer Syncs

I'm using Document attachments quite heavily. Basically every document had a short 2kb binary data attached and I did not wanted to use base64 to attach the binary to the document's JSON, so I've used attachments. Worst idea ever.

I've noticed several of the Document lacking attachments - suddenly after sync the attachments became missing, CouchBase Lite would simply return `null` and my code would then fail since it expected a non-null binary (which should have been there in the first place!). Since Gateway has no state, the culprit is probably the CouchBase server itself. This conclusion is reinforced by the Sync simply failing because of getting 500 INTERNAL SERVER ERROR from the Gateway, which is apparently also confused where the hell those attachments vanished.

However, the outcome of this issue is that the Sync no longer works - every sync attempt is simply killed by 500 SERVER ERROR so nothing syncs, and the database is corrupted by missing attachments.

# Conclusion

The CouchBase software stack betrayed me so many times I've stopped counting. It wastes CPU and electricity, it silently corrupts the data, the code is horrible and stupid code practices are common. I consider the whole offering flaky and won't use it anymore.

CouchBase sucks, don't use it.
