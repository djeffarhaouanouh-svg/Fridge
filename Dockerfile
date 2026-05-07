FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG ANTHROPIC_API_KEY
ARG GOOGLE_VISION_API_KEY
ARG OPENAI_API_KEY
ARG SPOONACULAR_API_KEY
ARG GOOGLE_CSE_API_KEY
ARG PEXELS_API_KEY
ARG NEON_PASSWORD
ARG SPOONACULAR_KEY
ARG GOOGLE_CSE_KEY
ARG PEXELS_KEY

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN ANTHROPIC_CLEAN="$(printf '%s' "${ANTHROPIC_API_KEY}" | tr -d '\n\r')" && \
    OPENAI_CLEAN="$(printf '%s' "${OPENAI_API_KEY}" | tr -d '\n\r')" && \
    SPOONACULAR_FINAL="${SPOONACULAR_API_KEY:-$SPOONACULAR_KEY}" && \
    SPOONACULAR_CLEAN="$(printf '%s' "${SPOONACULAR_FINAL}" | tr -d '\n\r')" && \
    GOOGLE_CSE_FINAL="${GOOGLE_CSE_API_KEY:-$GOOGLE_CSE_KEY}" && \
    GOOGLE_CSE_CLEAN="$(printf '%s' "${GOOGLE_CSE_FINAL}" | tr -d '\n\r')" && \
    PEXELS_FINAL="${PEXELS_API_KEY:-$PEXELS_KEY}" && \
    PEXELS_CLEAN="$(printf '%s' "${PEXELS_FINAL}" | tr -d '\n\r')" && \
    NEON_CLEAN="$(printf '%s' "${NEON_PASSWORD}" | tr -d '\n\r')" && \
    printf '{\n  "ANTHROPIC_API_KEY": "%s",\n  "OPENAI_API_KEY": "%s",\n  "SPOONACULAR_API_KEY": "%s",\n  "GOOGLE_CSE_API_KEY": "%s",\n  "PEXELS_API_KEY": "%s",\n  "NEON_PASSWORD": "%s"\n}\n' \
      "${ANTHROPIC_CLEAN}" "${OPENAI_CLEAN}" "${SPOONACULAR_CLEAN}" "${GOOGLE_CSE_CLEAN}" "${PEXELS_CLEAN}" "${NEON_CLEAN}" \
      > /tmp/dart_defines.json
RUN flutter build web --release --pwa-strategy=none \
    --dart-define-from-file=/tmp/dart_defines.json

FROM nginx:alpine
RUN apk add --no-cache gettext
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf.template
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8080
# Runtime : NEON_DATABASE_URL (recommandé) ou NEON_PASSWORD pour le proxy → Neon.
ENTRYPOINT ["/docker-entrypoint.sh"]
