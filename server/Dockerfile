FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o /app/bin/medcare_backend

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl sqlite3 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/bin/medcare_backend /app/medcare_backend

ENV MEDCARE_HOST=0.0.0.0
ENV MEDCARE_PORT=8080
ENV MEDCARE_DB_PATH=/data/medcare_server.sqlite
VOLUME ["/data"]

EXPOSE 8080
CMD ["/app/medcare_backend"]
