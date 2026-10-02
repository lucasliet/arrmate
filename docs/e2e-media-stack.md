# End-to-end media lab

The lab is a Docker Compose stack that speaks the Radarr, Sonarr, Prowlarr, and
qBittorrent APIs Arrmate calls. Libraries, posters, release searches, the
activity queue, and download-client torrents are fixture data. Grabbing a
release in Radarr or Sonarr adds a torrent to the mocked qBittorrent, so the
app can be exercised with a filled library.

Prowlarr is not a screen in Arrmate. Its search API is what the interactive
release lists attribute to indexers such as `1337x (Prowlarr)`.

## Start

From the repository root, with Docker running:

```sh
docker compose -f tool/e2e/docker-compose.yml up -d --build
sh tool/e2e/smoke.sh
```

Stop the stack with:

```sh
docker compose -f tool/e2e/docker-compose.yml down
```

The process keeps state in memory. Restarting the container restores the
sample library.

## Instances to add in Arrmate

| Service | URL | API key or login |
| --- | --- | --- |
| Radarr | `http://127.0.0.1:7878` | `arrmate-radarr` |
| Sonarr | `http://127.0.0.1:8989` | `arrmate-sonarr` |
| qBittorrent | `http://127.0.0.1:8080` | `admin:adminarr` or bearer `arrmate-qbit` |
| Prowlarr | `http://127.0.0.1:9696` | `arrmate-prowlarr` |

Prowlarr has no instance type in the app. Call it directly when checking that
indexer results exist. On a device that is not the machine running Docker,
replace `127.0.0.1` with that machine's LAN address. Poster URLs follow the
host the app used to call the API.

## What the fixtures contain

Movies already in Radarr: Dune (file on disk), The Matrix (file on disk),
Arrival (monitored, no file), Oppenheimer (in cinemas, dated ahead of today).
Lookup also returns Inception and Blade Runner 2049, which are not in the
library.

Series already in Sonarr: Severance (partial season, one episode still airing)
and The Bear (complete). Lookup also returns Shogun.

qBittorrent starts with a download in progress (Dune), a seeding copy of The
Matrix, a second torrent with the same release name (cross-seed), a paused
Arrival download, an errored torrent, an unrelated seeding torrent, and the
Severance episode that is still downloading.

Radarr history for The Matrix uses the seeding torrent's infohash, so the
Matrix pair is a linked torrent plus a cross-seed. The concert bootleg matches
no library item.

## Pass through the app

Run these after the three instances test as connected. They are a quick smoke
pass; [e2e-feature-matrix.md](e2e-feature-matrix.md) lists every control with
its expected result and last tested status.

1. Movies library shows Dune, The Matrix, Arrival, and Oppenheimer with posters, years, and overviews. Search `matrix` keeps The Matrix. Sort and the monitored filter still leave a visible card.
2. Open Dune. The details screen shows the overview, poster or fanart, the 1080p file, and extra subtitle. History for that movie can be empty. The Matrix history lists grabbed and imported.
3. Add from lookup. Search `inception`, choose HD-1080p and `/movies`, and add it. The library gains Inception. Repeat on Series with `shogun`, HD-1080p, and `/tv`.
4. Interactive search on Arrival returns three Prowlarr releases. The 720p row is rejected. Grab the 1080p BluRay row. The activity queue and qBittorrent both gain that release.
5. Calendar shows Oppenheimer in cinemas and Severance's upcoming episode. Changing the visible month keeps those items inside the current window.
6. Activity queue lists the Dune download and the Arrival item waiting on manual import. Removing a queue item drops it from the list. History shows grabbed, imported, and failed events. Filtering by event type hides the others.
7. qBittorrent lists every sample torrent. Filters for downloading, seeding, paused, and error match Dune, The Matrix, Arrival, and Broken Sample. Pause and resume change Dune's state. The torrent sheet shows one file and a peer in Brazil. Delete the unrelated concert torrent and it leaves the list.
8. The Matrix seeding torrent links to the movie. The second torrent with the same name shows as a cross-seed. The concert torrent stays outside the library. Arrival's paused torrent is the download whose movie has no file yet.
9. Manual import from the Arrival queue item lists `Arrival 2016 WEBDL-1080p.mkv` already matched to Arrival.
10. Edit Arrival: change monitored state, quality profile, or root folder, save, leave the screen, and reopen. The edited values remain.
11. Settings shows system status for Radarr 5.18.4 and Sonarr 4.0.14, one health warning about the mocked download client, a log line from startup, quality profiles HD-1080p and Ultra-HD, and the root folder free space.
12. Series details for Severance lists season 1, episode files for the first two episodes, and the upcoming finale. Episode search returns Prowlarr releases. Grabbing one adds a Sonarr queue row and a `sonarr` category torrent.

Desktop and web layouts use the same data. Repeat library, calendar, activity, and settings at a narrow width and a wide width when the build under test is the responsive layout.
