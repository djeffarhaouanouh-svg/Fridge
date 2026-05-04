FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG ANTHROPIC_API_KEY
ARG SPOONACULAR_KEY
ARG GOOGLE_CSE_KEY

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release \
  --pwa-strategy=none \
  --dart-define=ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY} \
  --dart-define=SPOONACULAR_KEY=${SPOONACULAR_KEY} \
  --dart-define=GOOGLE_CSE_KEY=${GOOGLE_CSE_KEY}

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

EXPOSE 8080
CMD ["/bin/sh", "-c", "envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
