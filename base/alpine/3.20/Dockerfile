FROM alpine:3.20

ENV TZ=Asia/Shanghai

RUN apk add --no-cache tzdata \
  && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo "${TZ}" > /etc/timezone
