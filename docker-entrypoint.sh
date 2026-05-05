#!/bin/sh
set -e
# Auth Neon côté serveur uniquement (le navigateur ne peut pas appeler Neon directement — CORS).
export NEON_AUTH_HEADER="Basic $(printf '%s' "neondb_owner:${NEON_PASSWORD}" | base64 | tr -d '\n')"
envsubst '${PORT} ${NEON_AUTH_HEADER}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
exec nginx -g 'daemon off;'
