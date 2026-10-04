# CI / 本地构建基础镜像（对齐 postship docker-library 中 sola/build 用途）
FROM golang:1.25-alpine

ENV TZ=Asia/Shanghai

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
  && apk update --no-cache \
  && apk add --no-cache \
    git \
    docker-cli \
    openssh-client \
    make \
    gcc \
    g++ \
    musl-dev \
    linux-headers \
    bash \
    curl \
    tzdata \
    ca-certificates \
  && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo "${TZ}" > /etc/timezone
