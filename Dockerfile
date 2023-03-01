ARG IMAGEMAGICK_VERSION=7.1.0-62

FROM debian:bullseye-slim as base
WORKDIR /imagemagick

FROM base as downloader

ARG IMAGEMAGICK_VERSION
ENV IMAGEMAGICK_VERSION=$IMAGEMAGICK_VERSION
ENV IMAGEMAGICK_URL=https://github.com/ImageMagick/ImageMagick

RUN \
  apt-get update -y && \
  apt-get install -y curl && \
  curl -fsSLO ${IMAGEMAGICK_URL}/archive/${IMAGEMAGICK_VERSION}.tar.gz && \
  tar zxvf ${IMAGEMAGICK_VERSION}.tar.gz

FROM base as source

ARG IMAGEMAGICK_VERSION
ENV IMAGEMAGICK_VERSION=$IMAGEMAGICK_VERSION

COPY --from=downloader /imagemagick/ImageMagick-${IMAGEMAGICK_VERSION}/ ./

FROM source as builder

RUN \
  apt-get update -y && \
  apt-get install -y build-essential

RUN \
  apt-get install -y \
    libdjvulibre-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libopenexr-dev \
    libturbojpeg0-dev \
    libraqm-dev \
    libtiff-dev \
    libwebp-dev

RUN \
  LDFLAGS="-static" \
  ./configure \
    --without-magick-plus-plus \
    --without-perl \
    --enable-zero-configuration \
    --enable-hdri \
    --with-gvc \
    --with-rsvg \
    --with-wmf
RUN make && make install && make check

FROM base

LABEL org.opencontainers.image.source \
  https://github.com/mfinelli/docker-imagemagick

WORKDIR /
ARG IMAGEMAGICK_VERSION
ENV IMAGEMAGICK_VERSION=$IMAGEMAGICK_VERSION

RUN \
  apt-get update -y && \
  apt-get install -y \
    libjbig0 \
    libtiff5 \
    libraqm0 \
    libdjvulibre21 \
    libfontconfig1 \
    libwebpmux3 \
    libwebpdemux2 \
    libopenexr25 \
    libgomp1

COPY --from=source /imagemagick/ /usr/src/imagemagick/
COPY --from=builder /usr/local/bin/magick /usr/bin/
# COPY --from=builder /usr/local/share/man/man1/magick.1 /usr/share/man/man1/
