# docker-library

面向**国内网络环境**的基础 Docker 镜像仓库：将 Docker Hub / 上游官方镜像或定制 Dockerfile **同步/构建** 后推送到**腾讯云容器镜像服务（CCR）**，供 CI、CVM 及本地开发从国内节点快速拉取，避免直连国外 registry 慢、超时或不稳定的问题。

目录约定参考 [docker-library](https://github.com/docker-library)（`<name>/<version>/<variant>/Dockerfile`）。

## 国内加速设计

| 层面 | 做法 |
|------|------|
| **镜像分发** | 统一推送到腾讯云 CCR（`ccr.ccs.tencentyun.com`），拉取走国内 CDN |
| **构建基础层** | Alpine 系镜像替换为清华 apk 源；Python 使用清华 pip 源 |
| **运行时默认** | 全量镜像设置 `TZ=Asia/Shanghai` |
| **本地 Docker** | 构建时可配置腾讯云镜像加速：`https://mirror.ccs.tencentyun.com` |

**镜像地址格式：**

```text
ccr.ccs.tencentyun.com/solat/<name>:<tag>
```

例如 `ccr.ccs.tencentyun.com/solat/postgres:16-pgcron-pgnet`。

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
    └── build-push-images.yml
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
| postgres | PG16 + pg_cron + pg_net | `16-pgcron-pgnet`, `latest` |
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
```

多版本/多变体：在同镜像名下新增版本或变体子目录（如 `golang/1.23/alpine/Dockerfile`），并在 `images.json` 中增加对应条目。每次推送还会额外打上 `sha-<7位commit>` 标签。

## GitHub Actions

`build-push-images.yml` — 构建并推送到腾讯云 CCR（TCR 个人版）。

| 触发 | 行为 |
|------|------|
| push `main` / `master` | 构建有改动的镜像并 **push 到 CCR** |
| PR | 仅构建验证，不 push |
| `workflow_dispatch` | 可指定 `image` 或留空构建全部；`push` 默认开启，可关闭 |

**所需 Secrets（Repository → Settings → Secrets）：**

| Secret | 说明 |
|--------|------|
| `TENCENT_REGISTRY_USERNAME` | CCR 登录用户名（个人版一般为腾讯云账号 ID） |
| `TENCENT_REGISTRY_PASSWORD` | CCR 登录密码（控制台「访问凭证」中设置） |

## 使用示例

在 `docker-compose.yml` 或 CI 中直接引用 CCR 地址，替代 Docker Hub 等国外源：

```yaml
image: ccr.ccs.tencentyun.com/solat/redis:7
image: ccr.ccs.tencentyun.com/solat/postgres:16-pgcron-pgnet
image: ccr.ccs.tencentyun.com/solat/grafana:11.6.0
image: ccr.ccs.tencentyun.com/solat/loki:3.4.6
image: ccr.ccs.tencentyun.com/solat/elasticsearch:8.19.15
image: ccr.ccs.tencentyun.com/solat/elasticsearch:7.17.28   # ES 7 存量兼容
image: ccr.ccs.tencentyun.com/solat/geoserver:2.27.1
image: ccr.ccs.tencentyun.com/solat/openbao:2.4.4
image: ccr.ccs.tencentyun.com/solat/woodpecker-server:v3.15.0
image: ccr.ccs.tencentyun.com/solat/woodpecker-agent:v3.15.0
```

## 本地镜像加速配置

`registry-mirrors` 用于加速 **Docker Hub** 等公共源的 `docker pull` / `docker build`（Dockerfile 里的 `FROM alpine` 等）。本仓库已发布到 CCR 的镜像（`ccr.ccs.tencentyun.com/solat/...`）直接拉取即可，无需走 mirror。

推荐腾讯云加速地址：`https://mirror.ccs.tencentyun.com`

### Linux

编辑 `/etc/docker/daemon.json`（不存在则新建）：

```json
{
  "registry-mirrors": ["https://mirror.ccs.tencentyun.com"]
}
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

验证：`docker info | grep -A5 "Registry Mirrors"`

### macOS / Windows（Docker Desktop）

**Settings → Docker Engine**，在 JSON 中加入 `registry-mirrors`，点击 **Apply & restart**：

```json
{
  "registry-mirrors": ["https://mirror.ccs.tencentyun.com"]
}
```

macOS 也可直接编辑 `~/.docker/daemon.json`，保存后重启 Docker Desktop。

### 拉取本仓库镜像

```bash
docker login ccr.ccs.tencentyun.com
docker pull ccr.ccs.tencentyun.com/solat/redis:7
```
