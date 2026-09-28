# Arrmate Web deployment

Arrmate Web runs in the user's browser. Credentials configured for a media
server are used by browser requests; a reverse proxy that forwards those
requests does not keep client-side credentials secret. Serve the app and any
proxy over HTTPS, and restrict access to the proxy endpoints.

## GitHub Pages release

The `publish-web.yml` workflow builds Flutter Web on pull requests, manual
runs, and version tags. A `v*` tag publishes the generated files to the
`gh-pages` branch and deploys the Pages artifact in the same workflow run.
Configure the repository's Pages source as **GitHub Actions**. The branch
contains the static build, while the Pages deployment uses the workflow
artifact because a `GITHUB_TOKEN` push does not start a separate Pages build.

The build uses `--base-href /arrmate/` for the repository URL
`https://<owner>.github.io/arrmate/`. It also publishes `404.html` as a copy of
`index.html` so refreshing a Flutter route loads the app, and `.nojekyll` so
GitHub Pages serves Flutter's generated files without Jekyll processing.

GitHub Pages serves static files and cannot proxy requests to Radarr, Sonarr,
or qBittorrent. Those services must be reachable from the browser over HTTPS
and allow the Pages origin, or the app must be hosted with a separately
configured reverse proxy. The online model catalog endpoint
`https://opencode.ai/zen/v1/models` currently blocks browser CORS, so the
Assistant online model flow also needs an HTTPS gateway at the app's origin
when hosted on Pages. OpenCode Zen's free models are restricted to the
official OpenCode client, and `x-opencode-session` does not bypass that policy.
Treat direct Zen support in Arrmate as a future fix. See the [Zen documentation](https://opencode.ai/docs/en/zen/)
and [OpenCode's free-tier policy](https://github.com/anomalyco/opencode/issues/49621).
Never put service credentials in the static build.

## Self-hosted reverse proxy

For a same-origin deployment, place the contents of `build/web` under
`/srv/arrmate` and serve the app at `/arrmate/`. The following Nginx controls
are for a private LAN or VPN deployment. Replace the example subnet and site
origin with the exact values for the deployment. The `map` and
`limit_req_zone` directives belong in the Nginx `http` context, before the
`server` block.

```nginx
map $http_origin $arrmate_origin_allowed {
  default 0;
  "https://arrmate.example.test" 1;
}

map "$request_method:$arrmate_origin_allowed" $arrmate_block_mutation {
  default 0;
  ~^(POST|PUT|PATCH|DELETE):0$ 1;
}

limit_req_zone $binary_remote_addr zone=arrmate_api:10m rate=20r/s;

server {
  listen 443 ssl http2;
  server_name arrmate.example.test;
  ssl_certificate /etc/letsencrypt/live/arrmate.example.test/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/arrmate.example.test/privkey.pem;

  root /srv;
  client_max_body_size 50m;

  allow 192.168.1.0/24;
  deny all;

  location ~* ^/arrmate/.*\.(?:js|wasm|png|webp|woff|woff2|ttf|otf|json|jpg|jpeg|svg|ico|css)$ {
    try_files $uri =404;
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; connect-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'" always;
  }

  location = /arrmate/index.html {
    add_header Cache-Control "no-cache";
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; connect-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'" always;
  }

  location /arrmate/ {
    try_files $uri $uri/ /arrmate/index.html;
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data: https:; connect-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'" always;
  }

  location /radarr/ {
    if ($arrmate_block_mutation) { return 403; }
    limit_req zone=arrmate_api burst=40 nodelay;
    proxy_pass http://radarr:7878/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }

  location /sonarr/ {
    if ($arrmate_block_mutation) { return 403; }
    limit_req zone=arrmate_api burst=40 nodelay;
    proxy_pass http://sonarr:8989/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }

  location /qb/ {
    if ($arrmate_block_mutation) { return 403; }
    limit_req zone=arrmate_api burst=40 nodelay;
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

The allowlist limits both the app and the service proxies to the stated
private network. Set it to the actual LAN or VPN CIDR; do not use a public
client address range. The exact `Origin` check rejects browser mutations from
other sites, and the rate limit bounds request volume. These controls do not
provide individual user identity. For an internet-facing deployment, put an
identity-aware gateway in front of the app and all three API locations, and
keep the service APIs inaccessible outside that gateway. If another proxy
sits in front of Nginx, configure trusted client-IP forwarding before relying
on the IP allowlist or per-client rate limit.

The Content Security Policy permits same-origin API calls. If the browser
connects directly to a service on another origin, add only that exact HTTPS
origin to `connect-src` and configure the service to allow the exact Arrmate
origin. Do not use a wildcard CORS origin for credentialed requests.
