FROM library/alpine:3.7
LABEL description="The Radicale CalDAV/CardDAV server as a Docker image." \
      maintainer="Alexander Mueller <XelaRellum@web.de>"

RUN set -xe && \
    apk update && apk upgrade && \
    apk add --no-cache --virtual=run-deps \
        apache2-utils curl git python3 py3-bcrypt py3-cffi

# Add s6 overlay
# Note: Tweak this line if you're running anything other than x86 AMD64 (64-bit)
RUN curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v1.19.1.1/s6-overlay-amd64.tar.gz | tar xvzf - -C /
    
RUN set -xe && \
    pip3 install radicale passlib bcrypt

RUN set -xe && \
    apk del --no-cache --progress --purge curl

# Add user radicale
RUN adduser -D -h /var/radicale -s /bin/false -u 1000 radicale radicale && \
    mkdir -p /var/radicale && \
    chown radicale.radicale /var/radicale

# Copy root file system
COPY root /

# expose radicale port
EXPOSE 8000

VOLUME ["/var/radicale"]

ENTRYPOINT ["/init"]
