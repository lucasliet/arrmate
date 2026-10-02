#!/bin/sh
# Hits the media lab APIs and fails if a response the app depends on is missing.
set -eu

radarr() {
  curl -fsS -H 'X-Api-Key: arrmate-radarr' "$@"
}

sonarr() {
  curl -fsS -H 'X-Api-Key: arrmate-sonarr' "$@"
}

prowlarr() {
  curl -fsS -H 'X-Api-Key: arrmate-prowlarr' "$@"
}

echo "ping"
curl -fsS http://127.0.0.1:7878/ping | grep -q OK
curl -fsS http://127.0.0.1:8989/ping | grep -q OK

echo "libraries"
radarr http://127.0.0.1:7878/api/v3/movie | grep -q Dune
sonarr http://127.0.0.1:8989/api/v3/series | grep -q Severance
radarr 'http://127.0.0.1:7878/api/v3/movie/lookup?term=inception' | grep -q Inception
sonarr 'http://127.0.0.1:8989/api/v3/series/lookup?term=shogun' | grep -q Shogun

echo "covers"
radarr -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7878/MediaCover/438631/poster.jpg | grep -q 200

echo "releases and queue"
radarr 'http://127.0.0.1:7878/api/v3/release?movieId=3' | grep -q Prowlarr
radarr http://127.0.0.1:7878/api/v3/queue | grep -q Arrival
sonarr http://127.0.0.1:8989/api/v3/queue | grep -q Severance
prowlarr 'http://127.0.0.1:9696/api/v1/search?query=Dune' | grep -q 1337x

echo "qBittorrent"
curl -fsS -c /tmp/arrmate-qbit.cookie -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=admin&password=adminarr' http://127.0.0.1:8080/api/v2/auth/login | grep -q Ok
curl -fsS -b /tmp/arrmate-qbit.cookie http://127.0.0.1:8080/api/v2/torrents/info | grep -q Matrix
curl -fsS -H 'Authorization: Bearer arrmate-qbit' http://127.0.0.1:8080/api/v2/app/version | grep -q v5

echo "grab"
radarr -X POST -H 'Content-Type: application/json' \
  -d '{"guid":"movie-3-1080","indexerId":"1"}' \
  http://127.0.0.1:7878/api/v3/release >/dev/null
curl -fsS -H 'Authorization: Bearer arrmate-qbit' http://127.0.0.1:8080/api/v2/torrents/info | grep -q 'Arrival 2016'

echo "media lab smoke passed"
