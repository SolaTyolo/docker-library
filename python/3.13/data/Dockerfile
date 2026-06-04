FROM python:3.13-slim

ENV TZ=Asia/Shanghai
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    tzdata git curl build-essential libpq-dev \
  && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo "${TZ}" > /etc/timezone \
  && pip install --no-cache-dir \
    pandas numpy scipy sqlalchemy psycopg2-binary redis httpx pydantic openpyxl \
  && apt-get purge -y build-essential \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*
