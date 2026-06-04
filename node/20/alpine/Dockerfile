FROM node:20-alpine

ENV TZ=Asia/Shanghai

RUN apk add --no-cache tzdata git openssh-client bash \
  && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo "${TZ}" > /etc/timezone
