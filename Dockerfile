ARG NGINX_VERSION=1.25.3
FROM nginx:${NGINX_VERSION} as builder
ARG module_version=2.5.2
ARG TARGETARCH
ARG PSOL=jammy
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
        apt-get update && apt-get install -y \
        wget \
        tar \
        build-essential \
        xz-utils \
        git \
        build-essential \
        zlib1g-dev \
        libpcre3 \
        libpcre3-dev \
        unzip uuid-dev && \
    mkdir -p /opt/build-stage

WORKDIR /opt/build-stage

RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN wget https://github.com/nginx-modules/ngx_cache_purge/archive/refs/tags/${module_version}.tar.gz
RUN tar xfv $module_version.tar.gz
RUN tar zxvf nginx-${NGINX_VERSION}.tar.gz

WORKDIR nginx-${NGINX_VERSION}
RUN ./configure --with-compat --add-dynamic-module=../ngx_cache_purge-$module_version/ && \
    make modules

FROM nginx:${NGINX_VERSION} as final
COPY --from=builder /opt/build-pagespeed/nginx-${NGINX_VERSION}/objs/ngx_http_cache_purge_module.so /usr/lib/nginx/modules/