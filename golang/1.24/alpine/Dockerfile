FROM golang:1.24-alpine

ENV TZ=Asia/Shanghai

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
  && apk update --no-cache \
  && apk add --no-cache \
    git \
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
