FROM docker.io/library/alpine:3.24.1
LABEL description="The Radicale CalDAV/CardDAV server as a Docker image." \
    maintainer="Alexander Mueller <XelaRellum@web.de>"

RUN set -xe && \
    apk update && apk upgrade && \
    apk add --no-cache --virtual=run-deps \
    apache2-utils curl git python3 openssh-client

# Install uv to /usr/local/bin
RUN set -xe && \
    curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx && \
    rm -rf /root/.cargo /root/.local && \
    apk del --no-cache --progress --purge curl

# Add user radicale
RUN adduser -D -h /var/radicale -s /bin/false -u 1000 radicale radicale && \
    mkdir -p /var/radicale && \
    chown radicale:radicale /var/radicale && \
    # Clean
    rm -rf /var/cache/apk/*

# Keep uv-managed Python outside the Radicale data volume.
RUN mkdir -p /opt/uv/python && \
    chown -R radicale:radicale /opt/uv
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python

USER radicale

# Copy root file system
COPY --chown=radicale:radicale root /
COPY --chown=radicale:radicale config.ini /var/radicale/

RUN chmod u+x /srv/run-radicale.sh

# Install Python dependencies using uv
RUN cd /srv && uv sync

# Expose radicale port
EXPOSE 8000

VOLUME ["/var/radicale"]
VOLUME ["/home/radicale/.ssh"]

ENTRYPOINT ["/srv/run-radicale.sh"]
