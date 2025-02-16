FROM library/alpine:3.21.3
LABEL description="The Radicale CalDAV/CardDAV server as a Docker image." \
    maintainer="Alexander Mueller <XelaRellum@web.de>"

RUN set -xe && \
    apk update && apk upgrade && \
    apk add --no-cache --virtual=run-deps \
    apache2-utils curl git python3 py3-bcrypt py3-cffi py3-pip openssh-client

RUN set -xe && \
    pip3 install --break-system-packages \
    bcrypt passlib pytz radicale==3.4.1

RUN set -xe && \
    apk del --no-cache --progress --purge curl py3-pip

# Add user radicale
RUN adduser -D -h /var/radicale -s /bin/false -u 1000 radicale radicale && \
    mkdir -p /var/radicale && \
    chown radicale:radicale /var/radicale && \
    # Clean
    rm -rf /var/cache/apk/*

USER radicale

# Copy root file system
COPY --chown=radicale:radicale root /
COPY --chown=radicale:radicale config.ini /var/radicale/

RUN chmod u+x /srv/run-radicale.sh

# Expose radicale port
EXPOSE 8000

VOLUME ["/var/radicale"]
VOLUME ["/home/radicale/.ssh"]

ENTRYPOINT ["/srv/run-radicale.sh"]
