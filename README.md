# Tang

[![trivy](https://github.com/visibilityspots/dockerfile-tang/actions/workflows/trivy.yml/badge.svg)](https://github.com/visibilityspots/dockerfile-tang/actions/workflows/trivy.yml)
[![docker-hub-description](https://github.com/visibilityspots/dockerfile-tang/actions/workflows/docker-hub-description.yml/badge.svg)](https://github.com/visibilityspots/dockerfile-tang/actions/workflows/docker-hub-description.yml)
[![build status](https://github.com/visibilityspots/dockerfile-tang/actions/workflows/main.yml/badge.svg)](https://github.com/visibilityspots/dockerfile-tang/actions/workflows/main.yml)
[![gitHub release](https://img.shields.io/github/v/release/visibilityspots/dockerfile-tang)](https://github.com/visibilityspots/dockerfile-tang/releases)
[![docker image size](https://img.shields.io/docker/image-size/visibilityspots/tang/latest)](https://hub.docker.com/r/visibilityspots/tang)
[![docker pulls](https://img.shields.io/docker/pulls/visibilityspots/tang.svg)](https://hub.docker.com/r/visibilityspots/tang/)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

a docker container which runs a [tang](https://github.com/latchset/tang) server, the
network side of [clevis](https://github.com/latchset/clevis) network bound disk
encryption (NBDE). A machine bound to it unlocks its LUKS volume at boot as long as
it can reach this server, and falls back to its passphrase when it can't.

tang is compiled from the upstream release tag on the latest stable alpine and runs
in listen mode (`tangd -l`), so no socat or systemd socket activation is needed.

## run

```
$ docker run -p 8080:8080 -v tang-keys:/var/db/tang --name tang --rm visibilityspots/tang:v16
```

On the first start, with an empty `/var/db/tang`, a signing and an exchange key are
generated. Existing keys are never touched, so keep that directory on persistent
storage: losing it means every bound client falls back to its passphrase until it is
bound again.

The container runs as user `tang` (uid/gid 1000); the key directory has to be
writable for that uid.

Check the advertisement;

```
$ curl -s http://localhost:8080/adv | jose fmt -j- -Og payload -SyOg keys -AUo-
```

Bind a LUKS device to it on the client;

```
# clevis luks bind -d /dev/sda2 tang '{"url":"http://tang.example.org:8080"}'
```

## Configuration

Environment variables defaults are set in the Dockerfile and can be overriden;

```
ENV PORT 8080
ENV JWKDIR /var/db/tang
```

### Key rotation

```
$ docker exec tang /usr/libexec/tangd-rotate-keys -d /var/db/tang
```

then run `clevis luks regen` on every bound client. The old keys are kept as hidden
files so clients that are not regenerated yet keep working.

## build

```
$ docker build -t visibilityspots/tang:v16 .
```

### buildx

```
$ docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
$ docker buildx build -t visibilityspots/tang:v16 --platform linux/amd64,linux/arm64 --push .
```

### dgoss

I wrote some tests in a goss.yaml file which can be executed by [dgoss](https://github.com/goss-org/goss/tree/master/extras/dgoss) to test the created image

```
$ dgoss run visibilityspots/tang:v16
INFO: Starting docker container
INFO: Container ID: 1c0d3b9f
INFO: Sleeping for 0.2
INFO: Container health
INFO: Running Tests
...
Total Duration: 0.412s
Count: 19, Failed: 0, Skipped: 0
INFO: Deleting container
```

The tests check the generated keys and request a real advertisement from the running
server, not only whether the port is open.

### act

using [act](https://github.com/nektos/act#overview----) for local testing of the written github actions makes my life and commit history a lot easier;

```
Stage  Job ID  Job name  Workflow name           Workflow file               Events
0      update  update    docker-hub-description  docker-hub-description.yml  push
0      main    main      CI                      main.yml                    push,pull_request
0      scan    scan      trivy                   trivy.yml                   push,schedule,workflow_dispatch
```

## License

Distributed under the [MIT license](https://github.com/visibilityspots/dockerfile-tang/blob/main/LICENSE)
