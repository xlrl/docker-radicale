FROM library/alpine:3.19
LABEL description="The Radicale CalDAV/CardDAV server as a Docker image." \
    maintainer="Alexander Mueller <XelaRellum@web.de>"

ENV ARCH=x86_64
ENV S6_OVERLAY_VERSION="3.1.6.2"

RUN set -xe && \
    apk update && apk upgrade && \
    apk add --no-cache --virtual=run-deps \
    apache2-utils curl git python3 py3-bcrypt py3-cffi py3-pip openssh-client

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz


RUN set -xe && \
    pip3 install --break-system-packages \
    bcrypt passlib pytz radicale==3.1.9

RUN set -xe && \
    apk del --no-cache --progress --purge curl py3-pip

# Add user radicale
RUN adduser -D -h /var/radicale -s /bin/false -u 1000 radicale radicale && \
    mkdir -p /var/radicale && \
    chown radicale.radicale /var/radicale && \
    # Clean
    rm -rf /var/cache/apk/*

USER radicale

# Copy root file system
COPY --chown=radicale:radicale root /
COPY --chown=radicale:radicale config.ini /var/
RUN chmod u+x /etc/cont-init.d/99-radicale /etc/services.d/radicale-daemon/run

# expose radicale port
EXPOSE 8000

VOLUME ["/var/radicale"]
VOLUME ["/home/radicale/.ssh"]

ENTRYPOINT ["/init"]
