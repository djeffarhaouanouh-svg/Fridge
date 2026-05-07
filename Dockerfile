FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG ANTHROPIC_API_KEY
ARG GOOGLE_VISION_API_KEY
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
RUN SPOONACULAR_FINAL="${SPOONACULAR_API_KEY:-$SPOONACULAR_KEY}" && \
    GOOGLE_CSE_FINAL="${GOOGLE_CSE_API_KEY:-$GOOGLE_CSE_KEY}" && \
    PEXELS_FINAL="${PEXELS_API_KEY:-$PEXELS_KEY}" && \
    flutter build web --release --pwa-strategy=none \
    --dart-define=ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
    --dart-define=GOOGLE_VISION_API_KEY="${GOOGLE_VISION_API_KEY}" \
    --dart-define=SPOONACULAR_API_KEY="${SPOONACULAR_FINAL}" \
    --dart-define=GOOGLE_CSE_API_KEY="${GOOGLE_CSE_FINAL}" \
    --dart-define=PEXELS_API_KEY="${PEXELS_FINAL}" \
    --dart-define=NEON_PASSWORD="${NEON_PASSWORD}"

FROM nginx:alpine
RUN apk add --no-cache gettext
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf.template
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8080
# Runtime : NEON_DATABASE_URL (recommandé) ou NEON_PASSWORD pour le proxy → Neon.
ENTRYPOINT ["/docker-entrypoint.sh"]
