#!/bin/sh
set -e
# Neon `/sql` exige l’en-tête Neon-Connection-String (pas Authorization Basic).
# Préfère NEON_DATABASE_URL (copiée depuis le dashboard Neon). Sinon construit l’URL avec NEON_PASSWORD.
if [ -n "$NEON_DATABASE_URL" ]; then
  export NEON_CONNECTION_STRING="$NEON_DATABASE_URL"
else
  export NEON_CONNECTION_STRING="postgresql://neondb_owner:${NEON_PASSWORD}@ep-dawn-night-abd29yl2-pooler.eu-west-2.aws.neon.tech/neondb?sslmode=require"
fi
envsubst '${PORT} ${NEON_CONNECTION_STRING}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
exec nginx -g 'daemon off;'
