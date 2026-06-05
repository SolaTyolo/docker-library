# docker-library

Postship 团队的基础 Docker 镜像仓库：将上游官方镜像或定制 Dockerfile **同步/构建** 后推送到**腾讯云容器镜像服务（CCR）**，供 `postship/docker-library` 与各业务仓库在 CI、CVM 上拉取使用。

目录约定参考 [docker-library](https://github.com/docker-library)（`<name>/<version>/<variant>/Dockerfile`），发布与登录方式对齐 [postship/docker-library](https://github.com/postship/docker-library) 中的 `ccr.ccs.tencentyun.com` 约定。

**镜像地址格式：**

```text
ccr.ccs.tencentyun.com/<namespace>/<name>:<tag>
```

默认 `namespace` 为 `postship`，例如 `ccr.ccs.tencentyun.com/postship/postgres:16-pgcron-pgnet`。

## 目录结构

按 **镜像名 / 版本 / 变体** 分层，每层目录内固定使用 `Dockerfile`。

```text
docker-library/
├── images.json                    # 镜像清单（CI matrix 与本地脚本共用）
│
├── alpine/3.20/Dockerfile         # 基础系统
├── debian/bookworm-slim/Dockerfile
│
├── golang/1.22|1.23|1.24|1.25/alpine/Dockerfile   # 语言构建环境
├── node/20|22|24/alpine/Dockerfile
├── python/3.13/data/Dockerfile
├── build/ci/Dockerfile            # CI：go + docker-cli
├── woodpecker-server/3.15/Dockerfile   # CI/CD（Woodpecker）
├── woodpecker-agent/3.15/Dockerfile
│
├── postgres/16/                   # 数据存储（PG16 + pg_cron + pg_net）
├── redis/7/alpine/Dockerfile
├── elasticsearch/7.17/Dockerfile
├── elasticsearch/8.19/Dockerfile
├── rustfs/1.0/Dockerfile
│
├── rabbitmq/3.13/management-alpine/Dockerfile     # 消息 / 流
├── kafka/3.9/Dockerfile
│
├── grafana/11.6/Dockerfile        # 可观测性（Grafana 栈）
├── loki/3.4/Dockerfile
├── promtail/3.4/Dockerfile
├── alloy/1.7/Dockerfile
├── prometheus/3.3/Dockerfile
│
├── nginx/1.27/alpine/Dockerfile    # 网关 / 代理
├── traefik/3.1/Dockerfile
│
├── geoserver/2.27/Dockerfile       # GIS
├── openbao/2.4/Dockerfile          # 密钥管理（Vault 开源分支）
│
├── imgproxy/4.0/Dockerfile         # 文档 / 媒体 / 工具
├── gotenberg/8/Dockerfile
├── dbgate/7.1/alpine/Dockerfile
├── opa/0.69.0/Dockerfile
│
├── scripts/
│   ├── build-push.sh
│   └── changed-images.sh
└── .github/workflows/
    ├── build-push-images.yml
    └── deploy-tencent-cvm.yml
```

## 镜像列表

### 基础与构建

| 名称 | 说明 | 主要 tag |
|------|------|----------|
| alpine | 时区 Asia/Shanghai | `3.20`, `latest` |
| debian | bookworm-slim + ca-certificates | `bookworm-slim`, `latest` |
| golang | Go 1.22–1.25 Alpine 构建环境（清华 apk 源） | `1.22-alpine` … `1.25-alpine`, `latest` |
| node | Node 20–24 Alpine 构建环境 | `20-alpine` … `24-alpine`, `latest` |
| python | Python 3.13 数据分析环境（清华 pip 源） | `3.13-data`, `latest` |
| build | CI：golang + docker-cli + 编译工具链 | `ci`, `latest` |

### CI/CD

| 名称 | 说明 | 主要 tag |
|------|------|----------|
| woodpecker-server | Woodpecker CI 控制面（Web UI + API） | `v3.15.0`, `latest` |
| woodpecker-agent | Woodpecker CI 执行 Agent（跑 pipeline 步骤） | `v3.15.0`, `latest` |

典型部署：`woodpecker-server` + 一个或多个 `woodpecker-agent`，需配合 Forge（如 Gitea/GitHub）与数据库（如 postgres）。上游不使用 `latest` tag，本仓库额外提供 `latest` 指向当前同步版本。

### 数据存储与检索

| 名称 | 说明 | 主要 tag |
|------|------|----------|
| postgres | PG16 + pg_cron + pg_net（与 lowcode-scheduler 一致） | `16-pgcron-pgnet`, `latest` |
| redis | Redis 7 Alpine | `7`, `latest` |
| elasticsearch | Elasticsearch 7 / 8 搜索与分析引擎 | `7.17.28`, `8.19.15`, `latest` |
| rustfs | S3 兼容对象存储（MinIO 替代） | `1.0.0-beta.3`, `latest` |

### 消息队列

| 名称 | 说明 | 主要 tag |
|------|------|----------|
| rabbitmq | RabbitMQ 3.13 management | `3.13-management`, `latest` |
| kafka | Apache Kafka 3.9（KRaft，官方镜像） | `3.9`, `latest` |

### 可观测性（Grafana 栈）

| 名称 | 说明 | 主要 tag |
|------|------|----------|
| grafana | Grafana 可视化与告警面板 | `11.6.0`, `latest` |
| prometheus | Prometheus 指标采集与存储 | `3.3.1`, `latest` |
| loki | Loki 日志聚合 | `3.4.6`, `latest` |
| promtail | Promtail 日志采集 Agent（兼容存量部署） | `3.4.6`, `latest` |
| alloy | Grafana Alloy 统一采集 Agent（Promtail 继任） | `1.7.5`, `latest` |

典型组合：

```text
指标：Prometheus → Grafana
日志：Promtail / Alloy → Loki → Grafana
```

> Promtail 已于 2026-03 EOL，新部署建议优先使用 **Alloy**；存量 Promtail 配置可通过 [Grafana 迁移工具](https://grafana.com/docs/alloy/latest/set-up/migrate/from-promtail/) 转换。

### 网关与基础设施

| 名称 | 说明 | 主要 tag |
|------|------|----------|
| nginx | Nginx Alpine | `alpine`, `latest` |
| traefik | 反向代理 / API 网关 | `3.1`, `latest` |
| opa | Open Policy Agent 0.69 | `0.69.0`, `latest` |

### GIS、安全与工具

| 名称 | 说明 | 主要 tag |
|------|------|----------|
| geoserver | GeoServer 地图服务（kartoza 镜像） | `2.27.1`, `latest` |
| openbao | OpenBao 密钥与机密管理（HashiCorp Vault 开源分支） | `2.4.4`, `latest` |
| imgproxy | 图片变换（S3 直读） | `4.0.3`, `latest` |
| gotenberg | Office → PDF 文档转换 | `8`, `latest` |
| dbgate | 数据库管理 Web 平台 | `7.1.13-alpine`, `latest` |

### 新增镜像

在 `<name>/<version>/<variant>/` 下添加 `Dockerfile`，并在 `images.json` 中登记 `name`、`context`、`dockerfile`（固定为 `Dockerfile`）、`tags`。

## 本地构建与推送

**前置**：安装 `docker`、`jq`，并已 `docker login ccr.ccs.tencentyun.com`。

```bash
# 列出镜像
./scripts/build-push.sh --list

# 构建并推送单个镜像
./scripts/build-push.sh postgres
./scripts/build-push.sh grafana

# 仅构建不推送
PUSH=0 ./scripts/build-push.sh loki

# 构建全部
./scripts/build-push.sh --all

# 自定义命名空间（默认 postship）
NAMESPACE=sola ./scripts/build-push.sh redis
```

多版本/多变体：在同镜像名下新增版本或变体子目录（如 `golang/1.23/alpine/Dockerfile`），并在 `images.json` 中增加对应条目。每次推送还会额外打上 `sha-<7位commit>` 标签。

## GitHub Actions

### 1. `build-push-images.yml` — 构建并推送到 CCR

| 触发 | 行为 |
|------|------|
| push / PR `main` | 仅构建有改动的镜像目录；PR 只 build 不 push |
| `workflow_dispatch` | 可指定 `image` 或留空构建全部 |

**所需 Secrets（Repository → Settings → Secrets）：**

| Secret | 说明 |
|--------|------|
| `TENCENT_REGISTRY_USERNAME` | CCR 登录用户名（个人版一般为腾讯云账号 ID） |
| `TENCENT_REGISTRY_PASSWORD` | CCR 登录密码（控制台「访问凭证」中设置） |

### 2. `deploy-tencent-cvm.yml` — 在腾讯云 CVM 上拉取镜像

在基础镜像 **构建 workflow 成功** 后自动执行（也可手动 `workflow_dispatch`），通过 SSH 登录 CVM、`docker login` 后 `docker pull` 基础设施相关镜像。

**所需 Secrets：**

| Secret | 说明 |
|--------|------|
| `DEPLOY_HOST` | CVM 公网 IP 或域名 |
| `DEPLOY_USER` | SSH 用户（如 `ubuntu`） |
| `DEPLOY_SSH_KEY` | SSH 私钥全文 |
| `DEPLOY_PORT` | 可选，默认 22 |
| `DEPLOY_COMPOSE_DIR` | 可选，服务器上 `docker-compose.infra.yml` 所在目录；设置后会执行 `compose pull && up -d` |
| `TENCENT_REGISTRY_*` | 同构建 workflow，用于 CVM 上 docker login |

手动部署时可传 `images`，逗号分隔，例如：`postgres,redis,grafana,loki,prometheus,elasticsearch`。

## 与 postship/docker-library 的关系

| 仓库 | 职责 |
|------|------|
| **本仓库** | 基础/中间镜像的定义与发布到 CCR |
| **postship/docker-library** | 本地/服务器编排（compose）、init SQL、install 脚本、临时 token 拉私有镜像 |

将 compose 中的镜像逐步改为本仓库地址，例如：

```yaml
# 由
image: ccr.ccs.tencentyun.com/sola/redis:7
# 改为
image: ccr.ccs.tencentyun.com/postship/redis:7
```

`postgres` 与 `lowcode-scheduler/docker/postgres` 保持一致；scheduler 侧可改为直接引用 CCR：

`ccr.ccs.tencentyun.com/postship/postgres:16-pgcron-pgnet`

可观测性与 GIS 相关 compose 示例：

```yaml
image: ccr.ccs.tencentyun.com/postship/grafana:11.6.0
image: ccr.ccs.tencentyun.com/postship/loki:3.4.6
image: ccr.ccs.tencentyun.com/postship/elasticsearch:8.19.15
image: ccr.ccs.tencentyun.com/postship/elasticsearch:7.17.28   # ES 7 存量兼容
image: ccr.ccs.tencentyun.com/postship/geoserver:2.27.1
image: ccr.ccs.tencentyun.com/postship/openbao:2.4.4
image: ccr.ccs.tencentyun.com/postship/woodpecker-server:v3.15.0
image: ccr.ccs.tencentyun.com/postship/woodpecker-agent:v3.15.0
```

## 腾讯云 CCR 配置步骤

1. 开通 [容器镜像服务](https://console.cloud.tencent.com/tcr) 个人版。
2. 创建命名空间（与 `images.json` 中 `namespace` 一致，如 `postship`）。
3. 在「访问凭证」设置固定密码，写入 GitHub Secrets。
4. （可选）在 CVM 安装 Docker，开放 22 端口供 Actions SSH 部署。

国内构建可配置 Docker 镜像加速：`https://mirror.ccs.tencentyun.com`

## 参考

- [docker-library](https://github.com/docker-library) — 官方镜像仓库目录约定
- [Grafana Loki 文档](https://grafana.com/docs/loki/latest/) / [Alloy 迁移指南](https://grafana.com/docs/alloy/latest/set-up/migrate/from-promtail/)
- [Woodpecker CI 文档](https://woodpecker-ci.org/docs)
- postship/docker-library — CCR 登录、`install.sh infra`、compose 镜像引用
- [腾讯云 CCR 推送文档](https://cloud.tencent.com/document/product/1141/39271)
