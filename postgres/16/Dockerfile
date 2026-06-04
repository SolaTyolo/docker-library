# 与 lowcode-scheduler/docker/postgres 保持一致，便于统一发布到 CCR
ARG POSTGRES_IMAGE=public.ecr.aws/docker/library/postgres:16-bookworm
FROM ${POSTGRES_IMAGE}

ARG PG_NET_VERSION=0.20.2
ARG APT_DEBIAN_HOST=

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
				postgresql-16-cron \
				ca-certificates \
				curl \
				build-essential \
				postgresql-server-dev-16 \
				libcurl4-openssl-dev; \
		then \
			ok=1; \
			break; \
		fi; \
		echo "apt failed, sleeping before retry..."; \
		sleep "$((attempt * 8))"; \
	done; \
	test "$ok" -eq 1; \
	curl -fsSL --retry 8 --retry-delay 3 --retry-all-errors \
		"https://github.com/supabase/pg_net/archive/refs/tags/v${PG_NET_VERSION}.tar.gz" \
		| tar xz -C /tmp; \
	cd "/tmp/pg_net-${PG_NET_VERSION}"; \
	make; \
	make install; \
	cd /; \
	rm -rf "/tmp/pg_net-${PG_NET_VERSION}"; \
	apt-get purge -y curl build-essential postgresql-server-dev-16 libcurl4-openssl-dev; \
	apt-get install -y --no-install-recommends libcurl4; \
	apt-get autoremove -y; \
	rm -rf /var/lib/apt/lists/*

COPY init-pgcron.sql /docker-entrypoint-initdb.d/01-init-pgcron.sql
COPY init-pgnet.sql /docker-entrypoint-initdb.d/02-init-pgnet.sql
