FROM debian:buster-slim as base

RUN set -ex \
    # Create some directories to PostgreSQL install
    && mkdir -p /usr/share/man/man1 \
    && mkdir -p /usr/share/man/man7 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        # SeisComP4 dependencies
        flex \
        libboost-filesystem1.67.0 \
        libboost-iostreams1.67.0 \
        libboost-program-options1.67.0 \
        libboost-regex1.67.0 \
        libboost-signals1.67.0 \
        libboost-thread1.67.0 \
        libpq5 \
        libpython2.7 \
        libxml2 \
        python3 \
        python3-dateutil \
        python3-twisted \
        # Database dependencies
        libmariadb3 \
        postgresql \
        sqlite3 \
        # Graphical interface dependencies
        libqtgui4 \
        libqt4-xml \
        # Misc
        gosu \
        rsync \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/*

FROM base as builder
ENV WORK_DIR /opt/seiscomp4
ENV BUILD_DIR /tmp/seiscomp4
ENV INSTALL_DIR $WORK_DIR
ENV SEISCOMP4_CONFIG /data/seiscomp4
ENV LOCAL_CONFIG /data/.seiscomp4
ENV ENTRYPOINT_INIT /docker-entrypoint-init.d
ENV PATH $PATH:$INSTALL_DIR/bin:$INSTALL_DIR/sbin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$INSTALL_DIR/lib
ENV PYTHONPATH $PYTHONPATH:$INSTALL_DIR/lib/python

ARG SEISCOMP_VERSION=4.7.2
RUN cd /tmp \
    && wget https://www.seiscomp.de/downloader/seiscomp-$SEISCOMP_VERSION-debian10-x86_64.tar.gz \
    && tar -xzvf "seiscomp-$SEISCOMP_VERSION-debian10-x86_64.tar.gz" \
    && mv seiscomp $INSTALL_DIR

FROM base as app

ENV WORK_DIR /opt/seiscomp4
ENV BUILD_DIR /tmp/seiscomp4
ENV INSTALL_DIR $WORK_DIR
ENV SEISCOMP4_CONFIG /data/seiscomp4
ENV LOCAL_CONFIG /data/.seiscomp4
ENV ENTRYPOINT_INIT /docker-entrypoint-init.d
ENV PATH $PATH:$INSTALL_DIR/bin:$INSTALL_DIR/sbin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$INSTALL_DIR/lib
ENV PYTHONPATH $PYTHONPATH:$INSTALL_DIR/lib/python




COPY --from=builder $INSTALL_DIR $INSTALL_DIR

RUN set -ex \
    && useradd -m -s /bin/bash sysop \
    && chown -R sysop:sysop $INSTALL_DIR \
    && mkdir -p /data \
    && chown sysop:sysop /data

USER sysop

RUN set -ex \
    && mkdir -p $SEISCOMP4_CONFIG \
    && mkdir -p $LOCAL_CONFIG \
    && mkdir -p $HOME/.seiscomp4

USER root