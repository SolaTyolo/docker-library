FROM nginx:1.27-alpine

ENV TZ=Asia/Shanghai

RUN apk add --no-cache tzdata \
  && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo "${TZ}" > /etc/timezone
