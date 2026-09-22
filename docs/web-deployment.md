# Arrmate Web deployment

Arrmate Web should be served over HTTPS behind a same-origin reverse proxy. A
same-origin deployment avoids exposing service credentials to browser scripts
and prevents mixed-content failures. Direct browser connections are intended
only for advanced trusted-network installations whose Radarr, Sonarr, and
qBittorrent servers explicitly allow the Arrmate origin.

## Build and base path

Build for an origin root with `flutter build web --release`. For a subpath,
pass `--base-href /arrmate/` and publish the generated `build/web` directory at
that exact path. The subpath location must return `/arrmate/index.html` for
unknown routes so refreshing `/arrmate/movies/123` restores the Flutter route.

## Reference nginx configuration

Replace the upstream addresses and allowed origin with values for your network.
Do not use a wildcard CORS origin when credentials are enabled.

```nginx
server {
  listen 443 ssl http2;
  server_name arrmate.example.test;

  root /srv/arrmate/web;
  client_max_body_size 50m;

  location / {
    try_files $uri $uri/ /index.html;
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; connect-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'" always;
  }

  location ~* \.(js|wasm|png|webp|woff2)$ {
    try_files $uri =404;
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; connect-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'" always;
  }

  location = /index.html {
    add_header Cache-Control "no-cache";
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; connect-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'" always;
  }

  location /radarr/ {
    proxy_pass http://radarr:7878/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }

  location /sonarr/ {
    proxy_pass http://sonarr:8989/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }

  location /qb/ {
    proxy_pass http://qbittorrent:8080/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
```

For a subpath deployment, replace the root, static asset, and `index.html`
locations with the following locations, and keep the service proxy locations
unchanged:

```nginx
location ~* ^/arrmate/(.+\.(?:js|wasm|png|webp|woff2))$ {
  alias /srv/arrmate/web/$1;
  expires 1y;
  add_header Cache-Control "public, immutable";
  add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; connect-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'" always;
}

location /arrmate/ {
  alias /srv/arrmate/web/;
  try_files $uri $uri/ /arrmate/index.html;
  add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; connect-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'" always;
}

location = /arrmate/index.html {
  alias /srv/arrmate/web/index.html;
  add_header Cache-Control "no-cache";
  add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; connect-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'" always;
}
```

## Security checklist

- Terminate TLS with a certificate trusted by every client browser.
- Keep API keys and passwords out of URLs, logs, exported diagnostics, and
  client-side analytics.
- If a gateway stores credentials, encrypt its configuration and authenticate
  browser sessions with `HttpOnly`, `Secure`, and `SameSite` cookies.
- Enforce CSRF tokens, exact origin checks, authorization, rate limits, and
  upload size limits at the gateway.
- Forward WebSocket or server-sent-event headers only on endpoints that need
  them.
- Never work around a browser TLS, CORS, or mixed-content error by disabling a
  browser security feature.
