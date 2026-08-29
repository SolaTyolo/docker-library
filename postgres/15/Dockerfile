# 与 postgres/16 同结构，便于统一发布到 CCR
ARG POSTGRES_IMAGE=public.ecr.aws/docker/library/postgres:15-bookworm
FROM ${POSTGRES_IMAGE}

ARG APT_DEBIAN_HOST=

# 仅安装组件，不在 initdb 时 CREATE EXTENSION / 不自动拉起 PgBouncer；
# 业务侧按需：CREATE EXTENSION vector / postgis / pg_cron；PgBouncer 自行配置启动。
# pg_cron 必须进 shared_preload_libraries，否则后续 CREATE EXTENSION 也无法加载。
RUN set -eux; \
	if [ -n "${APT_DEBIAN_HOST}" ]; then \
		find /etc/apt -type f \( -name '*.sources' -o -name '*.list' \) -print0 \
			| xargs -0 -r sed -i \
			"s/deb.debian.org/${APT_DEBIAN_HOST}/g; s/security.debian.org/${APT_DEBIAN_HOST}/g" || true; \
	fi; \
	printf '%s\n' \
		'Acquire::Retries "8";' \
		'Acquire::http::Timeout "120";' \
		'Acquire::https::Timeout "120";' \
		> /etc/apt/apt.conf.d/99network; \
	ok=0; \
	for attempt in 1 2 3 4 5 6 7 8; do \
		echo "apt install attempt $attempt/8..."; \
		if apt-get update \
			&& apt-get install -y --no-install-recommends \
				postgresql-15-cron \
				postgresql-15-pgvector \
				postgresql-15-postgis-3 \
				postgresql-15-postgis-3-scripts \
				pgbouncer; \
		then \
			ok=1; \
			break; \
		fi; \
		echo "apt failed, sleeping before retry..."; \
		sleep "$((attempt * 8))"; \
	done; \
	test "$ok" -eq 1; \
	rm -rf /var/lib/apt/lists/*; \
	grep -q "shared_preload_libraries.*pg_cron" /usr/share/postgresql/postgresql.conf.sample \
		|| echo "shared_preload_libraries = 'pg_cron'" >> /usr/share/postgresql/postgresql.conf.sample
