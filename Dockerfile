FROM alpine:3.10

ARG UID=666
ARG GID=666
ARG BUILD_CORES

ENV RTORRENT_LISTEN_PORT=50000 \
    RTORRENT_DHT_PORT=6881 \
    RTORRENT_SCGI_PORT=16891 \
    RTORRENT_VER=0.9.8 \
    LIBTORRENT_VER=0.13.8 \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

ARG BUILD_DEPS="build-base git libtool automake autoconf wget tar xz zlib-dev cppunit-dev openssl-dev ncurses-dev curl-dev binutils linux-headers gettext"
ARG RUNTIME_DEPS="libintl ca-certificates curl ncurses openssl gzip zip zlib unrar findutils"

RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} && \
    apk update --quiet && \
    apk upgrade --quiet && \
    apk add --quiet --no-cache ${RUNTIME_DEPS} && \
    apk add --quiet --no-cache --virtual build-dependencies ${BUILD_DEPS} && \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    cd /tmp && \
    git clone --quiet https://github.com/rakshasa/libtorrent.git && \
    cd /tmp/libtorrent && \
    git checkout --quiet v${LIBTORRENT_VER} && \
    ./autogen.sh && \
    ./configure --quiet --enable-silent-rules && \
    make --silent -j${NB_CORES} && \
    make --silent install && \
    cd /tmp && \
    git clone --quiet https://github.com/mirror/xmlrpc-c.git && \
    cd /tmp/xmlrpc-c/advanced && \
    ./configure --quiet --disable-libwww-client --disable-wininet-client --disable-abyss-server --disable-cgi-server && \
    make --silent -j${NB_CORES} && \
    make --silent install && \
    cd /tmp && \
    git clone --quiet https://github.com/rakshasa/rtorrent.git && \
    cd /tmp/rtorrent && \
    git checkout --quiet v${RTORRENT_VER} && \
    ./autogen.sh && \
    ./configure --quiet --with-xmlrpc-c --with-ncurses --enable-ipv6 --enable-silent-rules && \
    make --silent -j${NB_CORES} && \
    make --silent install && \
    addgroup -g ${GID} rtorrent && \
    adduser -S -u ${UID} -G rtorrent rtorrent && \
    mkdir /home/rtorrent/rtorrent && \
    chown -R rtorrent:rtorrent /home/rtorrent/rtorrent && \
    apk del --quiet build-dependencies && \
    rm -rf /var/cache/apk/* /tmp/*

COPY --chown=rtorrent:rtorrent rtorrent.rc /home/rtorrent/.rtorrent.rc

EXPOSE 6881/tcp 6881/udp 16891/tcp 50000/tcp

USER rtorrent

CMD ["rtorrent"]
