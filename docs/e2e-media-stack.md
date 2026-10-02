# End-to-end media lab

The lab is a Docker Compose stack that speaks the Radarr, Sonarr, Prowlarr, and
qBittorrent APIs Arrmate calls. All four share one in-memory library, so an
action in one service shows up in the others the way it does on a real stack:

- Grabbing a release (interactive, automatic search, or add-and-search) adds a
  torrent, a queue item, and a `grabbed` history event. The grabbed torrent
  finishes in about a minute and imports itself: the movie or episodes gain a
  file, the queue item leaves, and an import event is recorded.
- The fixture downloads (Dune, Severance S01E09) creep forward in real time and
  stall at 97%, so the fixture queue stays stable for a whole test pass.
- Manual import writes the file, clears the queue item, and records the event.
- Removing a queue item honors Remove from Download Client, Blocklist, and
  Search for Replacement. A blocklisted release is rejected in later searches.
- Deleting a movie or series drops its history, as Radarr and Sonarr do, so its
  torrents become orphans. Deleting a file records a file-deleted event.
- The calendar honors the requested date range and the unmonitored flag.
- qBittorrent answers like 5.1.2: `stop`/`start` only, `stoppedDL`/`stoppedUP`
  states, the `stopped` add flag, persisted file priorities, and a recheck that
  returns to the previous state after three seconds.

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

Movies already in Radarr: Dune (1080p file on disk, a 2160p upgrade
downloading), The Matrix (file on disk), Arrival (monitored, no file, a
completed download waiting on manual import), Oppenheimer (in cinemas since five
days ago; digital release in 30 days, physical in 70). Lookup also returns
Inception and Blade Runner 2049, which are not in the library. Lookups accept
titles and `tmdb:` / `imdb:` ids (`tvdb:` / `imdb:` for series).

Series already in Sonarr: Severance and The Bear.

- Severance season 1 has 9 aired episodes; E01–E04 are on disk, E05 is stalled
  in the queue, E09 is downloading, and E06–E08 are missing. Season 2 starts in
  four days and airs weekly. A special (S00E01) airs in six days, unmonitored.
- The Bear season 1 is complete on disk (8 of 8) and the series is ended.
- Lookup also returns Shogun; adding it creates its ten aired episodes.

Root folders are `/movies` and `/movies-4k` in Radarr, `/tv` and `/tv-anime` in
Sonarr. Tags are `lab` and `4k`.

qBittorrent starts with nine torrents:

| Torrent | State | Category |
| --- | --- | --- |
| Dune 2021 Remux-2160p | downloading | `radarr` |
| The Matrix 1999 Bluray-1080p (40×`a`) | seeding | `radarr` |
| The Matrix 1999 Bluray-1080p (40×`b`) | seeding | `cross-seed` |
| Arrival 2016 WEBDL-1080p | stopped, complete | `radarr` |
| Broken Sample WEBDL-720p | error | `radarr` |
| Unrelated Concert Bootleg 2020 | seeding | none |
| Severance S01E01 | seeding | `sonarr` |
| Severance S01E09 | downloading | `sonarr` |
| Severance S01E05 | stalled | `sonarr` |

Movie torrents carry a video, a sample, and a subtitle file; the concert has
three audio tracks. History download ids are uppercase, as Radarr and Sonarr
store them for qBittorrent, so the Matrix pair is a linked torrent plus a
cross-seed. Broken Sample is an orphan in the `radarr` category, and the
concert matches no library item.

History also covers every event-type filter: grabbed, imported, failed
(Arrival's earlier HDTV grab), ignored, renamed (Dune), and the file-deleted
events the app creates.

## Pass through the app

Run these after the three instances test as connected. They are a quick smoke
pass; [e2e-feature-matrix.md](e2e-feature-matrix.md) lists every control with
its expected result and last tested status.

1. Movies library shows Dune, The Matrix, Arrival, and Oppenheimer with posters, years, and overviews. Search `matrix` keeps The Matrix. Sort and the monitored filter still leave a visible card.
2. Open Dune. The details screen shows the overview, poster or fanart, the 1080p file, and its subtitle and NFO extras. The Matrix history lists grabbed and imported.
3. Add from lookup. Search `inception`, choose HD-1080p and `/movies`, and add it. The library gains Inception. Repeat on Series with `shogun`, HD-1080p, and `/tv`; Shogun arrives with ten episodes.
4. Interactive search on Arrival returns four Prowlarr releases. The 720p row is rejected. Grab the 1080p BluRay row. The activity queue and qBittorrent both gain that release, and within about a minute Arrival has a file.
5. Calendar shows Oppenheimer in cinemas, the Severance special, and season 2. Load more adds Oppenheimer's physical release and the rest of season 2.
6. Activity queue lists Dune, Arrival waiting on manual import, and the two Severance downloads (E05 stalled as a warning). History shows grabbed, imported, failed, ignored, and renamed events. Filtering by event type hides the others.
7. qBittorrent lists every sample torrent. Filters for downloading, seeding, paused, and error match the table above. Stop and start change Dune's state. The Matrix file sheet shows three files and keeps priority changes. Delete the unrelated concert torrent and it leaves the list.
8. The Matrix seeding torrent links to the movie. The second torrent with the same name shows as a cross-seed. The concert torrent stays outside the library. Arrival's torrent is complete but its movie has no file.
9. Manual import from the Arrival queue item lists `Arrival 2016 WEBDL-1080p` matched to Arrival, plus the sample, which is rejected. Importing gives Arrival a file and clears the queue item.
10. Edit Arrival: change monitored state, quality profile, minimum availability, or root folder, save, leave the screen, and reopen. The edited values remain.
11. Settings shows system status for Radarr 5.18.4 and Sonarr 4.0.14, two health warnings, log lines at info, warn, and error level (commands add more), quality profiles HD-1080p and Ultra-HD, and both root folders' free space.
12. Series details for Severance lists seasons 1 and 2. Season 1 shows four files, the missing episodes, and the downloads. Episode search grabs a release that imports itself within a minute.

Desktop and web layouts use the same data. Repeat library, calendar, activity, and settings at a narrow width and a wide width when the build under test is the responsive layout.
