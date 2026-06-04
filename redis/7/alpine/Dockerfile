FROM redis:7-alpine

ENV TZ=Asia/Shanghai

RUN apk add --no-cache tzdata \
  && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo "${TZ}" > /etc/timezone
