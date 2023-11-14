ARG NGINX_VERSION=1.25.3
ARG MODULE_VERSION=2.5.2

FROM nginx:${NGINX_VERSION} as builder
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

RUN git clone https://github.com/nginx-modules/ngx_cache_purge.git && \
    cd ngx_cache_purge && \
    git checkout a84b0f3f082025dec737a537a9a443bdd6d6af9d #2.5.2

RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN tar zxvf nginx-${NGINX_VERSION}.tar.gz
WORKDIR nginx-${NGINX_VERSION}
RUN ./configure --with-compat --add-dynamic-module=../ngx_cache_purge/ && \
    make modules

FROM nginx:${NGINX_VERSION} as final
COPY --from=builder /opt/build-stage/nginx-${NGINX_VERSION}/objs/ngx_http_cache_purge_module.so /usr/lib/nginx/modules/
