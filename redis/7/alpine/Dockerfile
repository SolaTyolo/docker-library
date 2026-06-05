FROM redis:7-alpine AS builder

ARG REDISBLOOM_VERSION=v2.8.17

RUN apk add --no-cache git build-base linux-headers cmake bash python3 py3-pip \
  && git clone --recursive --depth 1 --branch "${REDISBLOOM_VERSION}" \
    https://github.com/RedisBloom/RedisBloom.git /tmp/RedisBloom

WORKDIR /tmp/RedisBloom
RUN make \
  && install -D "$(find bin -name redisbloom.so -type f | head -1)" /out/redisbloom.so

FROM redis:7-alpine

ENV TZ=Asia/Shanghai

RUN apk add --no-cache tzdata \
  && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo "${TZ}" > /etc/timezone

COPY --from=builder /out/redisbloom.so /usr/local/lib/redis/modules/redisbloom.so

CMD ["redis-server", "--loadmodule", "/usr/local/lib/redis/modules/redisbloom.so"]
