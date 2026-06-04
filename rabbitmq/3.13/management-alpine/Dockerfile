FROM rabbitmq:3.13-management-alpine

ENV TZ=Asia/Shanghai

RUN apk add --no-cache tzdata \
  && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo "${TZ}" > /etc/timezone
