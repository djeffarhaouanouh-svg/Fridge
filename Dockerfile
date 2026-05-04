FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG ANTHROPIC_API_KEY
ARG SPOONACULAR_KEY
ARG GOOGLE_CSE_KEY

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN printf "const kAnthropicKey = '${ANTHROPIC_API_KEY}';\nconst kSpoonacularKey = '${SPOONACULAR_KEY}';\nconst kGoogleCseKey = '${GOOGLE_CSE_KEY}';\n" > lib/core/config/app_secrets.dart
RUN flutter build web --release --pwa-strategy=none

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

EXPOSE 8080
CMD ["/bin/sh", "-c", "envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
