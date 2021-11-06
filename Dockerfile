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
        python \
        python-dateutil \
        python-twisted \
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

RUN set -ex \
    && buildDeps=' \
        build-essential \
        ca-certificates \
        cmake \
        default-libmysqlclient-dev \
        gfortran \
        git \
        libboost-dev \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-program-options-dev \
        libboost-regex-dev \
        libboost-signals-dev \
        libboost-thread-dev \
        libboost-test-dev \
        libfl-dev \
        libpq-dev \
        libqt4-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        python-dev \
        wget \
        ninja-build \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        $buildDeps
ARG SEISCOMP_VERSION=4.7.2
RUN cd /tmp \
    && wget https://github.com/SeisComP/seiscomp/archive/refs/tags/$SEISCOMP_VERSION.tar.gz \
    && tar -xzvf "$SEISCOMP_VERSION.tar.gz" \
    && mv seiscomp-$SEISCOMP_VERSION seiscomp4
RUN mkdir -p $BUILD_DIR/build \
    && cd $BUILD_DIR/build \
    && cmake \
        -G Ninja \
        -DSC_GLOBAL_GUI=ON \
        -DSC_TRUNK_DB_MYSQL=ON \
        -DSC_TRUNK_DB_POSTGRESQL=ON \
        -DSC_TRUNK_DB_SQLITE3=ON \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
        .. \
    && ninja \
    && ninja install

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