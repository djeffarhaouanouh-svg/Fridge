FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG ANTHROPIC_API_KEY
ARG SPOONACULAR_KEY
ARG GOOGLE_CSE_KEY
ARG PEXELS_KEY
ARG NEON_PASSWORD

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN mkdir -p lib/core/config && \
    ANTHROPIC=$(printf '%s' "${ANTHROPIC_API_KEY}" | tr -d '\n\r') && \
    SPOONACULAR=$(printf '%s' "${SPOONACULAR_KEY}" | tr -d '\n\r') && \
    GOOGLE=$(printf '%s' "${GOOGLE_CSE_KEY}" | tr -d '\n\r') && \
    PEXELS=$(printf '%s' "${PEXELS_KEY}" | tr -d '\n\r') && \
    NEON=$(printf '%s' "${NEON_PASSWORD}" | tr -d '\n\r') && \
    printf "const kAnthropicKey = '${ANTHROPIC}';\nconst kSpoonacularKey = '${SPOONACULAR}';\nconst kGoogleCseKey = '${GOOGLE}';\nconst kPexelsKey = '${PEXELS}';\nconst kNeonPassword = '${NEON}';\n" > lib/core/config/app_secrets.dart
RUN flutter build web --release --pwa-strategy=none

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

EXPOSE 8080
CMD ["/bin/sh", "-c", "envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
