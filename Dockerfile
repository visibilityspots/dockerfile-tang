ARG ALPINE_VERSION=3.24
ARG UPSTREAM_RELEASE_TAG=v16

FROM alpine:${ALPINE_VERSION} AS build
ARG UPSTREAM_RELEASE_TAG

RUN apk add --no-cache build-base meson ninja-build pkgconf curl tar jose-dev llhttp-dev && \
    mkdir /src && \
    curl -fsSL "https://github.com/latchset/tang/archive/refs/tags/${UPSTREAM_RELEASE_TAG}.tar.gz" | tar xz --strip 1 -C /src

WORKDIR /src

RUN meson setup build --prefix=/usr --libexecdir=libexec --buildtype=release && \
    meson compile -C build && \
    DESTDIR=/out meson install -C build

FROM alpine:${ALPINE_VERSION}

LABEL maintainer="Jan Collijs"

ENV PORT=8080
ENV JWKDIR=/var/db/tang

RUN addgroup -S -g 1000 tang && \
    adduser -S -D -H -u 1000 -G tang tang && \
    apk add --no-cache jose llhttp tini && \
    mkdir -p /var/db/tang && \
    chown tang:tang /var/db/tang

COPY --from=build /out/usr/ /usr/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

USER tang

VOLUME /var/db/tang
EXPOSE 8080

# tangd as PID 1 ignores SIGTERM; tini forwards it so a stop takes no 10 s kill timeout
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
