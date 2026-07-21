---
layout: post
title: Tips on CI
---

If you're looking for a self-hosted OSS free CI, this may give you some tips.

Requirements:

* Needs to be self-hosted, open-source and free
* Should use as few RAM as possible
* Should be able to periodically poll git repo

Evaluated CIs from [awesome-ci](https://github.com/ligurio/awesome-ci):

* [Jenkins](https://www.jenkins.io/) - the default choice. Can be configured to use 512m of RAM only.
  * Install [Jenkins on Linux](https://www.jenkins.io/doc/book/installing/linux)
  * Note that you configure Jenkins via `systemctl edit jenkins`, then restart via `systemctl restart jenkins`.
  * Logs accessible via `journalctl -u jenkins -f`
* CircleCI - self-hosted option is not free. Skip.
* Concourse-CI: The `fly` binary is suspicious; the YAML config is weird; simple git build example missing. Skip.
* AppCircle.io: self-hosted option is not free. Skip.
* Agola.io: PITA top setup, you need etcd cluster, object storage and whatever. Skip.
* OpenShift gitops? Based on huge OpenShift and 'only' adds in Argo CD. Skip.
* TeamCity - not bad, needs server+agent to be up-and-running but "only" uses 2G server + 700mb agent. Pass.
* [Laminar](https://laminar.ohwg.net/docs.html) - simple and awesome but can't poll git repo periodically.
  * Maybe a small kotlin-native repo poller which calls `laminarc queue foo`?
  * Or a [git pulling build bot](https://stackoverflow.com/questions/7166509/how-to-build-a-git-polling-build-bot).
  * Pass, but later since it needs git build bot.
