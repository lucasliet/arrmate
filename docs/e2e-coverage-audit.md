# End-to-end coverage audit

The media lab supports a useful subset of Arrmate's media workflows. It does
**not** establish end-to-end coverage of the whole application. The Docker
service mocks four APIs in one Python process; it does not run actual Radarr,
Sonarr, Prowlarr, or qBittorrent servers.

## Existing UI evidence

Audited the branch at `2263b10` and the two Cursor evidence reports in
[PR #38](https://github.com/lucasliet/arrmate/pull/38#issuecomment-5952057484) and
[the partial desktop pass](https://github.com/lucasliet/arrmate/pull/38#issuecomment-5953209855).
The reports concern desktop Linux and earlier commits (`86488ab` and
`2263b10`); they do not certify the current head or Windows/macOS/tablet runs.
The screenshots and recordings are hosted in Cursor's agent artifacts. Their
links and reported observations were reviewed, but the artifacts were not
independently replayed in this audit.

The checked-in manual matrix contains **269 cases**: **40 marked Verified**,
**13 Seen**, and **216 Not run**. Only 40/269 (14.9%) have a reported successful
UI action. This is a count of checklist statuses, not code coverage. API or
widget checks do not promote a manual case to Verified.

| Area | Cases | Verified | Seen | Not run |
| --- | ---: | ---: | ---: | ---: |
| Navigation and deep links | 21 | 10 | 0 | 11 |
| Movies, editing, discovery, release search | 71 | 27 | 1 | 43 |
| Series, seasons, episodes, editing | 37 | 0 | 0 | 37 |
| Calendar | 14 | 0 | 1 | 13 |
| Queue, history, import, torrents | 63 | 3 | 4 | 56 |
| Settings, instances, system tools | 41 | 0 | 7 | 34 |
| Notifications | 11 | 0 | 0 | 11 |
| Assistant | 4 | 0 | 0 | 4 |
| Guided tour | 5 | 0 | 0 | 5 |
| Updates | 2 | 0 | 0 | 2 |

The partial QA comment records 33 PASS, 4 FAIL, 12 BLOCKED, and 220 cases not
exercised. That is a separate pass result, not the accumulated status of the
matrix: three failures were incorrect expectations, and the mouse refresh
failure was fixed in `be7e455`. MOV-04 still needs a real UI recheck. The new
widget regression drives both actual library screens, with one filtered
result, and verifies a mouse drag clears the query and reloads their providers.
It does not claim a native desktop UI pass.

## Executable validation

| Check | What it proves | What it does not prove |
| --- | --- | --- |
| `./tool/ci_check.sh` | Unit/widget regressions, analysis, generated mocks, launcher icons | Full app interactions against a server |
| `test_driver/main_test.dart` | FlutterDriver connects | Any application feature; it only checks driver health |
| `sh tool/e2e/smoke.sh` | 16 HTTP scenarios against a fresh stateful lab | Arrmate rendering, navigation, persistence, platform plugins, or real-server compatibility |
| `Media Lab API Checks` workflow | Builds/runs the Compose lab, waits for health, executes the HTTP suite, uploads logs | Automated app UI coverage |
| Desktop build workflow | Windows/Linux/macOS compilation | Runtime behavior or OS integrations |

The API suite checks authentication (key and cookie), CORS preflight, lookup
`id: 0`, libraries and covers, profiles/folders/tags, health/logs/disk space,
calendar date ranges and specials, numeric history filtering and pagination,
torrent filters and linking inputs, add/edit round trips, season/episode
monitoring, cross-service grabs, stop/start/recheck, file priorities and
location, manual import, queue removal/blocklist, notification configuration,
paused magnet addition, automatic import in both services, file deletion, and
catalog deletion. A grab must create a **new hash** with a matching queue and
history row. This replaces the old smoke's substring check against an Arrival
torrent that already existed in the fixtures.

The previously reported 67 API checks were not checked into the branch. The
new suite provides a reproducible command and CI evidence. It mutates fixtures
and fails early when the lab is not fresh; restart it before another pass.

## Remaining coverage needed

1. Drive the actual application through the 229 cases without a Verified UI
   status, recording commit, platform, viewport, action, expected state, and
   evidence per ID. Start with series/episode parity, add/edit/save/reopen,
   interactive grab through import, queue removal switches, file deletion,
   purge/cross-seed cancellation, and torrent actions.
2. Repeat core navigation and destructive/media flows on Windows and macOS,
   native Android/iPadOS tablets, and the web build. Test content breakpoints
   599/600, 899/900, 1199/1200 after subtracting the rail, and 1439/1440,
   including mouse, wheel, keyboard, touch, resize, and orientation changes.
3. Exercise assistant online model selection, chat success/error/streaming,
   generation guards, draft preservation, and bounded model sheets on native
   desktop/tablet. Native online access must remain independent of browser
   CORS. Check local model download/import/switch/delete/cancel/error on native
   Android, and their absence on unsupported platforms. Four assistant rows
   do not inventory all these actions.
4. Validate notification configuration through Arrmate and real ntfy delivery,
   reconnect, foreground/background behavior, and notification center actions.
   The lab only stores *arr notification configuration; it does not serve ntfy
   or emit notifications when a simulated import finishes.
5. Validate clean-install onboarding, replay/skip and sample removal; restart
   persistence for instances, preferences and credentials; network loss,
   partial service errors, failover, cache behavior, and connection diagnostics.
   The lab has no switchable latency, 500 responses, or timeouts. Wrong keys
   can exercise authentication failures but cannot represent all failures.
6. Exercise OS file pickers (.torrent and model imports), clipboard/share,
   external URLs, and registered deep links on devices with those integrations.
   Windows/Linux do not register `arrmate://` in this change. Signed macOS
   credential persistence and Android release updates require suitable builds.
7. Run selected contracts against real, versioned Radarr/Sonarr/qBittorrent
   services. A passing mock can reproduce the same mistaken assumptions as a
   client. Validate qBittorrent 4.x fallback separately: this lab only models 5.x.

The checklist is a starting inventory. The additional platform, assistant,
error, persistence, and external-service scenarios above remain necessary
before describing the application as fully covered end to end.
