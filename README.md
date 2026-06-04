# docker-library

Postship 团队的基础 Docker 镜像仓库：将上游官方镜像或定制 Dockerfile **同步/构建** 后推送到**腾讯云容器镜像服务（CCR）**，供 `postship/docker-library` 与各业务仓库在 CI、CVM 上拉取使用。

写法参考 [docker-library](https://github.com/docker-library) 官方镜像仓库（`<name>/<version>/<variant>/Dockerfile`），发布与登录方式对齐 [postship/docker-library](https://github.com/postship/docker-library) 中的 `ccr.ccs.tencentyun.com` 约定。

## 目录结构

与 [docker-library](https://github.com/docker-library) 官方镜像仓库一致：按 **镜像名 / 版本 / 变体** 分层，每层目录内固定使用 `Dockerfile`（不再使用 `Dockerfile-<tag>` 命名）。

```text
docker-library/
├── images.json              # 镜像清单（CI matrix 与本地脚本共用）
├── alpine/3.20/Dockerfile
├── debian/bookworm-slim/Dockerfile
├── golang/1.22/alpine/Dockerfile
├── golang/1.23/alpine/Dockerfile
├── golang/1.24/alpine/Dockerfile
├── golang/1.25/alpine/Dockerfile
├── node/20/alpine/Dockerfile
├── nginx/1.27/alpine/Dockerfile
├── opa/0.69.0/Dockerfile
├── postgres/16/               # PG16 + pg_cron + pg_net（与 lowcode-scheduler 一致）
│   ├── Dockerfile
│   ├── init-pgcron.sql
│   └── init-pgnet.sql
├── redis/7/alpine/Dockerfile
├── rabbitmq/3.13/management-alpine/Dockerfile
├── kafka/3.9/Dockerfile
├── rustfs/1.0/Dockerfile
├── imgproxy/4.0/Dockerfile
├── gotenberg/8/Dockerfile
├── traefik/3.1/Dockerfile
├── build/ci/Dockerfile        # CI 构建环境（go + docker-cli）
├── scripts/
│   ├── build-push.sh
│   └── changed-images.sh
└── .github/workflows/
    ├── build-push-images.yml
    └── deploy-tencent-cvm.yml
```

每个镜像名对应 CCR 中的一个仓库，例如：

`ccr.ccs.tencentyun.com/postship/postgres:16-pgcron-pgnet`

## 镜像列表

| 名称 | 说明 | 主要 tag |
|------|------|----------|
| alpine | 时区 Asia/Shanghai | `3.20`, `latest` |
| debian | bookworm-slim + ca-certificates | `bookworm-slim`, `latest` |
| golang | Go 1.22–1.25 Alpine 构建环境（清华 apk 源） | `1.22-alpine` … `1.25-alpine`, `latest` |
| node | Node 20 Alpine | `20-alpine`, `latest` |
| nginx | Nginx Alpine | `alpine`, `latest` |
| opa | Open Policy Agent 0.69 | `0.69.0`, `latest` |
| postgres | PG16 + pg_cron + pg_net | `16-pgcron-pgnet`, `latest` |
| redis | Redis 7 Alpine | `7`, `latest` |
| rabbitmq | RabbitMQ 3.13 management | `3.13-management`, `latest` |
| kafka | Apache Kafka 3.9（KRaft，官方镜像） | `3.9`, `latest` |
| rustfs | S3 兼容对象存储（MinIO 替代） | `1.0.0-beta.3`, `latest` |
| imgproxy | 图片变换（S3 直读） | `4.0.3`, `latest` |
| gotenberg | Office → PDF 文档转换 | `8`, `latest` |
| traefik | 反向代理 / API 网关 | `3.1`, `latest` |
| build | CI：golang + docker-cli + 编译工具链 | `ci`, `latest` |

新增镜像：在 `<name>/<version>/<variant>/` 下添加 `Dockerfile`，并在 `images.json` 中登记 `name`、`context`（指向该目录）、`dockerfile`（固定为 `Dockerfile`）、`tags`。

## 本地构建与推送

**前置**：安装 `docker`、`jq`，并已 `docker login ccr.ccs.tencentyun.com`。

```bash
# 列出镜像
./scripts/build-push.sh --list

# 构建并推送单个镜像
./scripts/build-push.sh postgres

# 仅构建不推送
PUSH=0 ./scripts/build-push.sh golang

# 构建全部
./scripts/build-push.sh --all

# 自定义命名空间（默认 postship）
NAMESPACE=sola ./scripts/build-push.sh redis
```

多版本/多变体：在同镜像名下新增版本或变体子目录（如 `golang/1.23/alpine/Dockerfile`），并在 `images.json` 中增加对应条目。

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

推送地址：`ccr.ccs.tencentyun.com/<namespace>/<name>:<tag>`，其中 `namespace` 来自 `images.json`（默认 `postship`）。每次构建额外打上 `sha-<7位commit>` 标签。

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

手动部署时可传 `images`，逗号分隔，例如：`postgres,redis,nginx`。

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

## 腾讯云 CCR 配置步骤

1. 开通 [容器镜像服务](https://console.cloud.tencent.com/tcr) 个人版。
2. 创建命名空间（与 `images.json` 中 `namespace` 一致，如 `postship`）。
3. 在「访问凭证」设置固定密码，写入 GitHub Secrets。
4. （可选）在 CVM 安装 Docker，开放 22 端口供 Actions SSH 部署。

国内构建可配置 Docker 镜像加速：`https://mirror.ccs.tencentyun.com`

## 参考

- [docker-library](https://github.com/docker-library) — 官方镜像仓库目录约定（版本/变体子目录 + `Dockerfile`）
- postship/docker-library — CCR 登录、`install.sh infra`、compose 镜像引用
- [腾讯云 CCR 推送文档](https://cloud.tencent.com/document/product/1141/39271)
