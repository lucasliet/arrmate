# End-to-end feature matrix

A manual checklist of Arrmate screens and controls, with expected results
against the media lab described in [e2e-media-stack.md](e2e-media-stack.md).
It is a partial coverage inventory; listing a case does not mean it has been
executed. See [e2e-coverage-audit.md](e2e-coverage-audit.md) for the coverage
audit, executable checks, and remaining application and platform scenarios.

## How to read this file

- **ID** is stable. Reference it in QA reports (`MOV-12 FAIL: ...`).
- **Expected** uses lab fixture data. Restart the container to restore it:
  `docker compose -f tool/e2e/docker-compose.yml up -d --force-recreate`.
- **Status** records the last real UI pass. Navigation, movies, Discover
  through DIS-15, the series library list, and the calendar, queue, and
  history lists were verified on desktop. Rows still marked `Not run` were
  not driven, or failed and still need a retest:
  - `Verified`: the action was run and the result matched.
  - `Seen`: the screen rendered with lab data, but its actions were not run.
  - `Not run`: never exercised in the UI.
  - `N/A`: not implemented in the app (see [Behavior gaps](#behavior-gaps-found-while-mapping)).
- **Expected** follows the current lab, which models grabs, imports, queue
  removal, and deletions. Some expectations changed after the last pass; rerun
  those rows rather than trusting their old status.

Destructive rows (delete, purge, remove, reset) change lab state. Run them last
in each section, or restart the lab before the next section.

## Lab fixtures used below

| Kind | Items |
| --- | --- |
| Radarr movies | Dune (id 1, 1080p on disk, 2160p upgrade downloading), The Matrix (id 2, on disk), Arrival (id 3, monitored, no file, completed download awaiting manual import), Oppenheimer (id 4, in cinemas since 5 days ago; digital +30 days, physical +70) |
| Radarr lookup only | Inception (tmdb 27205, `tt1375666`), Blade Runner 2049 (tmdb 335984), both `id: 0` |
| Sonarr series | Severance (id 1: S01 4 of 9 on disk, E05 stalled, E09 downloading, E06–E08 missing; S02 ten episodes from +4 days weekly; S00E01 special at +6 days, unmonitored), The Bear (id 2, 8 of 8, ended) |
| Sonarr lookup only | Shogun (tvdb 417742, `id: 0`, ten episodes once added) |
| Profiles / folders / tags | HD-1080p and Ultra-HD; `/movies`, `/movies-4k`, `/tv`, `/tv-anime`; tags `lab` and `4k` |
| Movie releases | 4 Prowlarr rows per movie; the 720p row is rejected |
| Radarr queue | Dune downloading; Arrival warning, import pending (manual import) |
| Sonarr queue | Severance S01E09 downloading; Severance S01E05 stalled (warning) |
| qBittorrent | Dune (downloading, `radarr`, 40×`c`), The Matrix (seeding, `radarr`, 40×`a`), The Matrix cross-seed (seeding, `cross-seed`, 40×`b`), Arrival (stopped, complete, `radarr`, 40×`d`), Broken Sample (error, `radarr`), Unrelated Concert Bootleg 2020 (seeding, no category), Severance S01E01 (seeding, `sonarr`, 40×`9`), S01E09 (downloading, `sonarr`, 40×`8`), S01E05 (stalled, `sonarr`, 40×`7`) |
| History | Dune grabbed + imported + renamed + 2160p grab; Matrix grabbed + imported (40×`a`); Arrival HDTV grabbed + failed, WEBDL grabbed (40×`d`); Oppenheimer ignored; The Bear pack grabbed + imported, one ignored; Severance S01E01–E04 grabbed + imported, E05 and E09 grabbed |

Grabs, searches, imports, queue removals, and deletions change this state the
way a real stack would; see [Media lab limits](#media-lab-limits) for what the
lab still does not model.

---

## Shell and navigation (NAV)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| NAV-01 | Bottom navigation | Window width < 600 | Bottom bar with Movies, Series, Calendar, Activity, Settings | Verified |
| NAV-02 | Icon rail | Width 600–899 | Icon-only rail, brand mark, same 5 destinations | Verified |
| NAV-03 | Labeled sidebar | Width ≥ 900 (and ≥ 1440) | Extended rail with labels and “ARRMATE” | Verified |
| NAV-04 | Tab switch | Tap each destination | Route changes to `/movies`, `/series`, `/calendar`, `/activity`, `/settings`; active tab highlighted | Verified |
| NAV-05 | Resize while open | Drag window across 600 and 900 | Navigation swaps without losing the current screen or state | Verified |
| NAV-06 | Content width cap | Width > 1600 | Content stays centered at 1600 max | Verified |
| NAV-07 | Notification bell | Tap bell on any tab | Opens `/notifications`; badge shows unread count, `99+` above 99 | Verified |
| NAV-08 | Rail bell on nested routes | Wide layout, open a movie | Bell appears in rail trailing area without tooltip | Verified |
| NAV-09 | Offline banner | Disconnect network | “Offline” banner with last-online time and the 7-day image cache note; disappears on reconnect | Not run |
| NAV-10 | Home tab on launch | Set Home Tab (SET-04), restart app | App opens on the chosen tab | Verified |
| NAV-11 | Adaptive sheets | Open any sheet at < 600 and ≥ 600 | Bottom sheet at both widths, drag handle included. Wide windows keep it width-capped along the bottom; it is not a centered dialog | Verified |

## Deep links (LNK)

`arrmate://` is registered on Android, iOS, and macOS. Windows and Linux builds
do not register the scheme, so run this section on those three platforms only.

| ID | Link | Expected | Status |
| --- | --- | --- | --- |
| LNK-01 | `arrmate:///movies/2` | The Matrix details | Not run |
| LNK-02 | `arrmate://movies/2` (host form) | Same as LNK-01 | Not run |
| LNK-03 | `arrmate:///series/1` | Severance details | Not run |
| LNK-04 | `arrmate:///series/1/season/1` | Severance season 1 | Not run |
| LNK-05 | `arrmate:///series/1/season/1/episode/11` | Season 1 with episode sheet open | Not run |
| LNK-06 | `/calendar`, `/activity`, `/notifications`, `/settings` | Each screen opens | Not run |
| LNK-07 | `/discover?type=series`, `/search?q=inception&type=movie` | Discover in the right mode, query prefilled | Not run |
| LNK-08 | `/settings/{logs,health,diagnostics,system-overview,quality-profiles,version-history,notifications,assistant}` | Each screen opens | Not run |
| LNK-09 | `/settings/instance/new` | Add Instance form | Not run |
| LNK-10 | Invalid: `/movies/0`, `/calendar/1`, `/settings/system-management`, other scheme | Ignored, current screen stays | Not run |

---

## Movies library (MOV)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| MOV-01 | Library load | Open Movies | Dune, The Matrix, Arrival, Oppenheimer with posters and years | Verified |
| MOV-02 | Grid / list toggle | Tap view icon twice | Switches grid ↔ list; tooltip flips “Switch to List/Grid”; choice persists after restart | Verified |
| MOV-03 | Search | Tap search, type `matrix` | Only The Matrix; close (X) restores all | Verified |
| MOV-04 | Pull to refresh | Pull down with a search active, including a mouse drag on a short list | Search cleared, list reloads | Verified |
| MOV-05 | Sort: Title / Year / Added / Rating / Size / Runtime / Grabbed / Digital Release | Sort sheet, pick each | Order changes for each value; sheet closes on pick | Verified |
| MOV-06 | Order Ascending / Descending | Sort sheet | Order inverts | Verified |
| MOV-07 | Filter All / Monitored / Unmonitored / Missing / Downloaded / Wanted / Dangling | Sort sheet, pick each | Downloaded = Dune, Matrix. Missing = Arrival only (monitored, no file, and available). Wanted = Arrival and Oppenheimer, because Oppenheimer is still in cinemas and not available yet. Unmonitored and Dangling empty until MOV-13 | Verified |
| MOV-08 | Root folder filter | Sort sheet → `/movies` and “All folders” | Chips are the folders movies already use: All folders and `/movies`. `/movies` keeps all four. `/movies-4k` appears only after a movie is moved there | Verified |
| MOV-09 | Filtered empty state | Filter Unmonitored | “No results found” with hint to clear filters | Verified |
| MOV-10 | Enter selection | Long-press Dune (grid and list) | “1 selected” app bar, batch bar, FAB hidden | Verified |
| MOV-11 | Add/remove from selection | Tap Matrix, tap Dune again | Count 2 → 1; deselecting last item exits selection | Verified |
| MOV-12 | Select all / close selection | Tap Select all, then X | Count equals visible (filtered) items; X clears | Verified |
| MOV-13 | Batch Unmonitor | Select Dune + Arrival → Unmonitor | Snackbar “Unmonitored 2 movies”; bookmark icons empty; reopen app, still unmonitored | Verified |
| MOV-14 | Batch Monitor | Select same → Monitor | “Monitored 2 movies”; icons filled | Verified |
| MOV-15 | Batch Delete | Select Oppenheimer → Delete → Delete; tick “Add to import exclusion list” | Confirm dialog; “Deleted 1 movie”; Oppenheimer gone from library and calendar | Verified |
| MOV-16 | Batch Delete files | Select Dune → Delete → Delete files | Confirm; “Deleted 1 file”; Dune shows missing; History gains a File Deleted event; Dune’s 2160p torrent stays In library (still downloading) | Verified |
| MOV-17 | Batch Purge | Select The Matrix → Delete → Purge | Confirm; seeding warning if seed time < minimum days (Cancel / Keep seeding / Delete all); cross-seed dialog for the 40×`b` copy (Keep / Delete); summary snackbar; Matrix gone from library and history, both torrents gone if approved; a kept cross-seed turns Orphan | Verified |
| MOV-18 | Batch cancel | Open any batch dialog, Cancel | No change | Verified |
| MOV-19 | Instance selector | Add a second Radarr instance (INS-12) | DNS icon appears; switching reloads the library; hidden with one instance | Not run |
| MOV-20 | Add entry point | Compact: FAB `+`; width ≥ 1200: “Add movie” button | Opens Discover in movie mode; FAB hidden on wide | Verified |
| MOV-21 | Queue indicator on card | Library with Dune queued | Dune card shows queue status tooltip | Verified |

## Movie details (MVD)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| MVD-01 | Open details | Tap Dune | Fanart, poster, overview, info grid (studio, status, profile, size, path) | Verified |
| MVD-02 | Poster viewer | Tap poster, scroll the wheel or trackpad up over the image, then Close | Fullscreen. Scroll up zooms in, up to 4×. Scroll down at 1× stays at 1×. Close dismisses it | Verified |
| MVD-03 | Ratings and status chip | Dune details | Rating badges with values > 0; “Downloaded” chip | Verified |
| MVD-04 | External links | Tap Trailer, IMDb, Trakt, Letterboxd | Browser opens; Trailer hidden without a trailer id | Verified |
| MVD-05 | Refresh & Scan | App bar | Snackbar “Refresh & Scan triggered”; ARR log gains “Updating info for …” and “Scanning disk for …” | Not run |
| MVD-06 | Automatic Search | App bar | Snackbar “Search started”. On Arrival: a 1080p BluRay grab joins the queue and imports within about a minute. On Dune (has a file): nothing grabbed | Not run |
| MVD-07 | Monitor toggle | App bar on Arrival, twice | “Unmonitored” then “Monitored”; library icon follows | Verified |
| MVD-08 | Files section | Dune details | One 1080p file card; tap opens File Details sheet with codecs/size | Not run |
| MVD-09 | Delete single file | File card trash → Delete | “File deleted”; section shows “No media files”; status chip changes; History gains a File Deleted event | Not run |
| MVD-10 | Extra files | Dune details | `Dune (2021).en.srt` subtitle and `Dune (2021).nfo` metadata cards (display only); none on a movie without a file | Verified |
| MVD-11 | History section | The Matrix details | Grabbed and imported events; tap opens event sheet | Verified |
| MVD-12 | Torrents section | The Matrix details | Both Matrix torrents (linked + cross-seed); tap opens torrent sheet without “Open in library” | Verified |
| MVD-13 | Torrents section empty | Oppenheimer details | “No torrents in the download client” | Verified |
| MVD-14 | Menu → Edit | Overflow → Edit | Edit Movie screen (MVE) | Verified |
| MVD-15 | Menu → Delete files | Dune overflow | Enabled when the movie has a file, disabled for Arrival; confirm → “Deleted 1 file” | Verified |
| MVD-16 | Menu → Delete | Overflow → Delete; try both checkboxes | “Also delete files from disk” and “Prevent re-add”; snackbar “Movie deleted” or “Movie and files deleted”; returns to the library. The copy in the Radarr category becomes Orphan. A cross-seed kept in another category (the lab uses `cross-seed`) becomes Not in library: once the movie and its history are gone, only a managed category is classified as Orphan | Verified |
| MVD-17 | Menu → Purge | Overflow → Purge | Same flow as MOV-17 for one movie; “Movie purged.” summary | Verified |
| MVD-18 | Wide vs compact hero | Content width < 1200 and ≥ 1200, after subtracting the rail | Hero 300/360, poster 100/180, padding 16/32 | Verified |

## Interactive search (REL)

Shared by movies, seasons, and episodes.

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| REL-01 | Open | Arrival → Interactive Search | Four Prowlarr releases, count “4 results” | Seen |
| REL-02 | Rejected row | Look at the 720p row | Dimmed, strikethrough, first rejection reason, download disabled, row tap disabled, info icon works | Verified |
| REL-03 | Search releases | Type `bluray` | List narrows; count shows “· N hidden”; clear X restores | Verified |
| REL-04 | Sort: Release weight / Quality weight / Custom format score / Seeders / Age / Size / Indexer | Sort menu | Order changes; rejected rows stay last | Verified |
| REL-05 | Sort direction | Arrow | Toggles ascending/descending | Verified |
| REL-06 | Filters sheet | Approval, Freeleech, Protocol, Indexer, Quality, Language, Custom format, Original language | Each narrows the list; Release type only on series; Clear filters and Apply work | Verified |
| REL-07 | Remember filters | Enable, close, reopen search | Filters restored | Verified |
| REL-08 | Toolbar Clear | With filters active | Clears filters, keeps sort | Verified |
| REL-09 | Release details | Info icon | Details sheet; “Download release” or “Release rejected” | Verified |
| REL-10 | Grab | Download icon on 1080p BluRay → Download | “Release grabbed successfully”; sheet closes; Radarr queue and qBittorrent gain the release; within about a minute the torrent seeds, the queue item leaves, and the movie has a file | Verified |
| REL-11 | Grab cancel | Download icon → Cancel | Nothing grabbed | Verified |

## Movie edit (MVE)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| MVE-01 | Monitored switch | Toggle, Save | “Movie updated”; persists on reopen | Verified |
| MVE-02 | Quality Profile | Change to Ultra-HD, Save | Info grid shows Ultra-HD | Verified |
| MVE-03 | Minimum Availability | Announced / In Cinemas / Released | Saved; reopening shows the new value. Oppenheimer set to In Cinemas becomes available (Wanted filter) | Verified |
| MVE-04 | Root Folder | Change folder on Dune | “Move Files?” dialog (Yes/No) because Dune has a file; pick `/movies-4k`; path and file path move to `/movies-4k/Dune (2021)` | Verified |
| MVE-05 | Tags | Tick `lab`, Save | Tag saved. Both `lab` and `4k` are offered even when the saved instance snapshot only had `lab`, because the editor reloads tags from the server | Verified |
| MVE-06 | Back without saving | Change fields, back | No change persisted | Verified |

## Discover and add (DIS)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| DIS-01 | Search by title | Movies → Add → `inception` | Inception result, poster, year, rating | Verified |
| DIS-02 | Search by id / URL | `tmdb:27205`, `27205`, `imdb:tt1375666`, a TMDB URL | Each finds Inception (title, `tmdb:`, and `imdb:` lookups are all served by the lab) | Verified |
| DIS-03 | Hide already added | Search `matrix`, toggle chip | On (default): The Matrix hidden. Off: shown with green check | Verified |
| DIS-04 | Existing result tap | Chip off, tap The Matrix | Opens `/movies/2` | Verified |
| DIS-05 | Sort Relevant / Latest / Rating | Sort dropdown | Result order changes | Verified |
| DIS-06 | Preview | Tap Inception | “Movie Preview” with poster, overview, Configure Addition | Verified |
| DIS-07 | Configure fields | Configure Addition | Monitor (Movie / Movie + Collection / None), Minimum Availability, Quality Profile, Root Folder with free space, Tags | Verified |
| DIS-08 | Add movie | HD-1080p, `/movies`, Add | “Movie added successfully”; the library is shown with no red error; Inception is in the library; reopening Discover shows it as added; adding it again is rejected | Verified |
| DIS-09 | Add validation | Clear profile or folder, Add | Not reachable: the profile and folder dropdowns have no clear control, so the empty-selection snackbar cannot be driven | N/A |
| DIS-10 | Remembered defaults | Add a second movie | Previous profile/folder preselected | Verified |
| DIS-11 | Back navigation | Back from configure, preview, then Close | Returns step by step; Close leaves Discover and shows the library with no red error | Verified |
| DIS-12 | Series search | Series → Add → `shogun` | Shogun result, opens Series Preview | Verified |
| DIS-13 | Series configure | Configure Addition | Monitor (All, Future, Missing, Existing, Recent, Pilot, First Season, Last Season, Monitor/Unmonitor Specials, None), Monitor New Seasons, Series Type, Season Folder, Profile, Root Folder, Tags | Verified |
| DIS-14 | Add series | HD-1080p, `/tv`, Add | “Series added successfully”; Shogun in library with ten season 1 episodes, monitored per the Monitor choice (None or Future leaves them unmonitored) | Verified |
| DIS-15 | Series by id | `tvdb:417742`, `imdb:` | Shogun found (`imdb:tt2788316`) | Verified |

---

## Series library (SER)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| SER-01 | Library load | Open Series | Shogun, Severance, and The Bear with posters | Verified |
| SER-02 | Grid / list, search, pull to refresh | Same as MOV-02…04 | Same behavior | Verified |
| SER-03 | Sort: Title / Year / Added / Rating / Size / Next Airing / Previous Airing | Sort sheet | Order changes | Verified |
| SER-04 | Filter All / Monitored / Unmonitored / Ended / Continuing / Missing / Dangling | Sort sheet | Ended = The Bear and Shogun; Continuing and Missing = Severance | Verified |
| SER-05 | Root folder filter | `/tv` | Both series | Not run |
| SER-06 | Selection | Long-press, tap, Select all, X | Same as MOV-10…12 | Not run |
| SER-07 | Batch Unmonitor / Monitor | Select both | “Unmonitored 2 series” / “Monitored 2 series”; persists | Not run |
| SER-08 | Batch Delete | Select The Bear → Delete → Delete (exclusion checkbox) | “Deleted 1 series” | Not run |
| SER-09 | Batch Delete files | Select Severance → Delete files | “Deleted 4 files”; season 1 shows 0 of 9; History gains File Deleted events | Not run |
| SER-10 | Batch Purge | Select Severance → Purge | Seeding warning and cross-seed prompts as needed; summary; series and its torrents removed | Not run |
| SER-11 | Add entry point | FAB / “Add series” | Discover in series mode | Not run |

## Series details (SED)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| SED-01 | Open details | Tap Severance | Fanart, poster, status, network, overview, info grid | Not run |
| SED-02 | Poster viewer, external links | Poster, IMDb / Trakt / TVDB | Same as MVD-02/04 | Not run |
| SED-03 | Refresh & Scan, Automatic Search | App bar | “Refresh & Scan triggered”, “Search started”; the search grabs E06–E08 (E05 and E09 are already queued) and they import within about a minute | Not run |
| SED-04 | Monitor toggle | App bar twice | “Unmonitored” / “Monitored” | Not run |
| SED-05 | Seasons All / None | Seasons header | “All seasons monitored” / “All seasons unmonitored”; season bookmarks follow | Not run |
| SED-06 | Season monitor | Season 1 bookmark | Toggles; series monitored follows any season | Not run |
| SED-07 | Season menu → Automatic / Interactive search | Season ⋮ | “Searching for Severance - Season 1...” then “Search started”; interactive mode lists a season pack and single-episode releases | Not run |
| SED-08 | Season multi-select | Long-press season 1; All / None | Season batch bar: Search, Unmonitor, Delete → Delete files / Purge | Not run |
| SED-09 | Season batch Search / Unmonitor | Batch bar | “Search started for 1 season” / “Unmonitored 1 season” | Not run |
| SED-10 | Season batch Delete files / Purge | Batch submenu | Confirm; “Deleted N files” / “Purged 1 season: …”; series stays | Not run |
| SED-11 | Torrents section | Severance details | The three Severance torrents (S01E01 seeding, S01E05 stalled, S01E09 downloading); tap opens sheet | Not run |
| SED-12 | Menu → Edit / Delete files / Delete / Purge | Overflow | Delete files disabled when no files; Delete dialog with files + re-add checkboxes; Purge summary “Series purged.” | Not run |
| SED-13 | Specials hidden | Series with season 0 | Season 0 (the S00E01 special) never listed | Not run |

## Season and episode (EPI)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| EPI-01 | Season list | Tap season 1 | Season 1: E01–E04 with files, E05 and E09 in the queue, E06–E08 missing. Season 2: ten upcoming episodes | Not run |
| EPI-02 | Episode monitor | Bookmark on an episode | “Episode monitored” / “Episode unmonitored” | Not run |
| EPI-03 | Episode automatic search | Episode row action | “Searching for S01E0x...” then “Search started for …”; a missing aired episode gets a grab that imports within about a minute | Not run |
| EPI-04 | Episode interactive search + grab | Episode row → releases → grab | Releases list only that episode; grab adds a Sonarr queue row and a `sonarr` torrent, which imports within about a minute | Not run |
| EPI-05 | Season app bar searches | Automatic / Interactive | Same as SED-07 | Not run |
| EPI-06 | Delete season files / Purge season | Season app bar | Disabled when no files; confirm; snackbar | Not run |
| EPI-07 | Episode sheet | Tap S01E01 | Air date, runtime, status, file card, torrents (S01E01 seeding torrent), history | Not run |
| EPI-08 | Episode file details / delete | File card tap, trash | Details sheet; “File deleted”; season count drops by one | Not run |
| EPI-09 | Episode history event | Tap event | Read-only event sheet | Not run |

## Series edit (SEE)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| SEE-01 | Monitored, Monitor New Seasons, Season Folders | Toggle, Save | Saved, screen pops | Not run |
| SEE-02 | Series Type Standard / Daily / Anime | Dropdown, Save | Persists on reopen | Not run |
| SEE-03 | Quality Profile, Root Folder | Change, Save | Root change asks “Move Files?” | Not run |
| SEE-04 | Tags | Tick `lab` | Saved | Not run |

---

## Calendar (CAL)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| CAL-01 | Event list | Open Calendar | Oppenheimer (In Cinemas, five days ago), Severance S00E01 special, and Severance S02E01–E06 under TODAY / TOMORROW / dated headers | Verified |
| CAL-02 | Instance filter | Any instance / Radarr / Sonarr | Narrows to that instance | Not run |
| CAL-03 | Media type filter | All media / Movies / Series | Narrows by type | Verified |
| CAL-04 | Monitored chip | Enable chip; then unmonitor Oppenheimer | Enable chip: the unmonitored S00E01 special hides. Unmonitor Oppenheimer (MVD-07): it hides too | Not run |
| CAL-05 | Premieres chip | Enable | Only S02E01 among episodes; movies stay | Not run |
| CAL-06 | Hide specials chip | Enable | S00E01 hidden | Not run |
| CAL-07 | Reset chip | With any filter active | Visible only then; clears all | Not run |
| CAL-08 | Filtered empty | Filters hiding everything | “No matching events” | Not run |
| CAL-09 | Tap movie event | Oppenheimer | Movie details | Not run |
| CAL-10 | Tap episode event | Severance episode | Season screen with that episode sheet open | Not run |
| CAL-11 | Load more | Button at bottom | Next 45 days appended: Oppenheimer physical release and Severance S02E07–E10 | Not run |
| CAL-12 | Pull to refresh | Pull down | Reloads, keeps list while loading | Not run |
| CAL-13 | Wide layout | Width ≥ 900 | Date sections in two columns | Verified |
| CAL-14 | Partial failure banner | Stop one instance (wrong key) | Banner lists the failed instance, Retry | Not run |

---

## Activity: Queue (QUE)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| QUE-01 | Queue list | Activity → Queue | Dune downloading, Arrival with “Manual Import required”, Severance S01E09 downloading, Severance S01E05 stalled; summary “4 tasks (2 problems)” | Verified |
| QUE-02 | Refresh icon | App bar | Queue, history, torrents reload | Not run |
| QUE-03 | Pull to refresh | Pull down | Reload | Not run |
| QUE-04 | Options: Instance / Protocol / Client | Tune icon | Each dropdown narrows; badge on tune icon | Not run |
| QUE-05 | Options: Problems only | Switch | Only Arrival and Severance S01E05 | Not run |
| QUE-06 | Options: sort Title / Added, Ascending / Descending, Reset, Apply | Sheet | Order changes; Reset restores defaults | Not run |
| QUE-07 | Filtered empty | Filters hiding all | “No matching tasks” + Clear filters | Not run |
| QUE-08 | Item sheet | Tap Dune | Status, progress + ETA (Dune creeps forward), info rows (quality, indexer, protocol, client, path) | Not run |
| QUE-09 | Open Movie / Open Series | Item sheet | Navigates to the media | Not run |
| QUE-10 | Removal switches | Item sheet | Remove from Download Client (on), Add to Blocklist, Search for Replacement (hidden while Blocklist is on) | Not run |
| QUE-11 | Remove from Queue | Severance S01E05 → Remove, then repeat with each switch | “Item removed from queue”; row gone. Remove from Download Client on: the torrent leaves qBittorrent. Blocklist on: History gains Download Failed and, unless replacement is off, another release is grabbed; the blocklisted one shows rejected in interactive search | Not run |
| QUE-12 | Live update | Leave Queue open | Polls every 5 s | Not run |

## Activity: Manual import (IMP)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| IMP-01 | Open | Arrival item → Manual Import | `Arrival 2016 WEBDL-1080p` matched to Arrival; the sample is listed with a `Sample` rejection | Not run |
| IMP-02 | Toggle file | Untick / tick | Import button hides with 0 selected | Not run |
| IMP-03 | Import | Import | “1 file(s) imported successfully”; Arrival gains a file; the queue item leaves; History gains Folder Imported | Not run |

## Activity: History (HIS)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| HIS-01 | List | History tab | Grabbed, Imported, Failed events from both apps, newest first | Verified |
| HIS-02 | Event filter values | Release Grabbed / Folder Imported / Download Failed / Download Ignored / File Renamed / File Deleted | Server-filtered list per type. Grabbed: every grab. Folder Imported: Dune, Matrix, Severance, The Bear. Failed: Arrival HDTV. Ignored: Oppenheimer CAM, The Bear 720p. Renamed: Dune. Deleted: empty until a file is deleted | Not run |
| HIS-03 | Instance filter | All instances / each | Client-side narrow | Not run |
| HIS-04 | Clear chip | With filters | Clears both | Not run |
| HIS-05 | Event sheet | Tap event | Badge, description, quality, language, date, indexer, client, score | Not run |
| HIS-06 | Load More / pull to refresh | Bottom / pull | More pages; button hidden when exhausted | Not run |

## Activity: Torrents list (TOR)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| TOR-01 | Tab visible | qBittorrent configured | Third tab “Torrents”; hidden without qBittorrent | Seen |
| TOR-02 | List | Torrents tab | All 9 fixture torrents with state, progress, speeds, seed time | Seen |
| TOR-03 | Search | `matrix` | Two Matrix torrents; clear X | Not run |
| TOR-04 | Sort Activity / Added date / Progress / Size / Download speed / Ratio / Seed time / Name | Sort menu | Order changes per field | Not run |
| TOR-05 | Sort direction | Arrow | Inverts | Not run |
| TOR-06 | Status: Downloading | Filters | Dune, Severance S01E09, Severance S01E05 (stalled); “3 torrents · 6 hidden” | Verified |
| TOR-07 | Status: Seeding | Filters | Both Matrix copies, concert, Severance S01E01 | Verified |
| TOR-08 | Status: Paused / Error | Filters | Paused: Arrival (stopped, complete) / Error: Broken Sample | Not run |
| TOR-09 | Link: In library | Filters | Matrix (`radarr`), Matrix cross-seed, Dune, the three Severance torrents | Not run |
| TOR-10 | Link: File removed | Filters | Arrival (complete, movie has no file); empty after IMP-03 | Not run |
| TOR-11 | Link: Orphan | Filters | `radarr`-category torrents with no Radarr match (Broken Sample); red border | Not run |
| TOR-12 | Link: Not in library | Filters | Unrelated Concert Bootleg 2020 | Not run |
| TOR-13 | Link section hidden | Remove Radarr and Sonarr instances | Library link section absent from filters | Not run |
| TOR-14 | Remember filters | Enable, restart app | Search, filters, sort restored | Not run |
| TOR-15 | Clear filters / Apply / toolbar Clear | Sheet and toolbar | Clear keeps sort | Not run |
| TOR-16 | Matrix badges | Seeding list | `radarr` copy “The Matrix”; cross-seed copy “The Matrix” + “Cross-seed” | Verified |
| TOR-17 | Episode badge | Severance torrents | “Severance · S01E01” / “· S01E05” / “· S01E09” | Not run |
| TOR-18 | Pull to refresh | Pull down | Torrents and link index reload | Not run |
| TOR-19 | Live update | Keep tab open | Dune and S01E09 progress grows every poll; grabbed torrents finish in about a minute | Not run |

## Activity: Torrent sheet and actions (TRA)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| TRA-01 | Open sheet | Tap Dune | Progress, ETA, Total Size, Downloaded, Uploaded, Ratio, speeds, Seeds, Leechers, Added On, Category, Save Path, Tags, Hash | Not run |
| TRA-02 | Media Library section | Matrix sheets | Linked description; cross-seed italic note on the `b` copy; Media and Instance rows | Not run |
| TRA-03 | Open in library | Matrix sheet → Open in library | The Matrix details on the right instance | Not run |
| TRA-04 | Pause | Dune → Pause | Sheet closes; Dune shows paused (`stoppedDL`); appears under Paused; its queue item shows paused | Not run |
| TRA-05 | Resume | Dune → Resume | Back to downloading | Not run |
| TRA-06 | Recheck | Any → Recheck | State becomes checking for about 3 s, then returns to the previous state | Not run |
| TRA-07 | Files sheet | Files | Movie torrents list three files (video, sample, subtitle); checkbox toggles Do Not Download (strikethrough) and persists on reopen | Not run |
| TRA-08 | File priority | Row ⋮ → High / Normal / Low / Do Not Download | Checkmark moves and persists on reopen | Not run |
| TRA-09 | Peers | Tap Seeds/Leechers | One peer, Brazil, qBittorrent 5.1.2; none on stopped torrents | Not run |
| TRA-10 | Move | Move → `/downloads/moved` → Move | “Location moved successfully. Data is being moved.”; Save Path updated | Not run |
| TRA-11 | Move validation | Empty path | “Please enter a valid path” | Not run |
| TRA-12 | Import to Media Library visibility | Dune (incomplete) vs Matrix (complete) | Button only on complete torrents | Not run |
| TRA-13 | Import target | Import → Movies / Series tabs, search | Monitored items only | Not run |
| TRA-14 | Import files | Pick a movie → tick file → Import | “1 file(s) imported successfully”; the movie gains a file. The list shows every completed file under the torrent’s save path, not just this torrent (see gaps) | Not run |
| TRA-15 | Remove, seeding warning | Concert → Remove Torrent | “Torrent still seeding” if seed time < minimum days (Keep torrent / Delete anyway) | Not run |
| TRA-16 | Remove dialog | Remove; with and without “Also delete files on disk” | Torrent leaves the list; Cancel keeps it | Not run |

## Activity: Add torrent (ADD)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| ADD-01 | Open | FAB `+` (and empty-state button) | “Add Torrent” sheet | Not run |
| ADD-02 | Magnet / URLs | Paste a magnet, Add Torrent | “Torrent added successfully”; new downloading row named from the magnet `dn`; finishes in about a minute | Not run |
| ADD-03 | .torrent file | Select .torrent File, then X | Card with filename; URL field hidden; X restores it | Not run |
| ADD-04 | Category autocomplete | Focus Category | Suggests `radarr`, `sonarr`, `cross-seed`; free text allowed | Not run |
| ADD-05 | Tags autocomplete | Type, comma | Chips `arrmate`, `cross-seed`; chip delete | Not run |
| ADD-06 | Save path, Start Paused | Fill, Add | Torrent added stopped at that path (needs the `stopped` flag, sent since commit `b15ac6f`) | Not run |
| ADD-07 | Validation | Empty source | “Please provide URLs or select a .torrent file” | Not run |

---

## Settings home (SET)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| SET-01 | Instances list | Settings | Each instance with URL, version, tag count | Seen |
| SET-02 | Theme Mode | System / Light / Dark | Theme switches immediately; persists | Not run |
| SET-03 | Color Scheme | Blue, Indigo, Purple, Pink, Red, Orange, Amber, Green, Teal | Accent changes | Not run |
| SET-04 | Home Tab | Movies / Series / Calendar / Activity | Saved; see NAV-10 | Not run |
| SET-05 | System Management tile | Tap | Opens SYS screen | Seen |
| SET-06 | Assistant tile | Tap | Opens ASI screen | Not run |
| SET-07 | Notification Settings / Center tiles | Tap | Open NTF screens; subtitles reflect state | Not run |
| SET-08 | Getting Started | Tap | Tour starts (TOU) | Not run |
| SET-09 | Version | Tap | Update check (Android release builds); “App is up to date” | Not run |
| SET-10 | Source Code | Tap | GitHub repository in browser | Not run |

## Instances (INS)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| INS-01 | Add Radarr | Type Radarr, `http://127.0.0.1:7878`, `arrmate-radarr`, Test | “Connection successful!” with version 5.18.4, instance name, “Tags: 2 available” | Seen |
| INS-02 | Add Sonarr | `:8989`, `arrmate-sonarr` | Version 4.0.14 | Seen |
| INS-03 | Add qBittorrent, bearer | `:8080`, API key `arrmate-qbit` | “Auth: API Key”, torrent count | Seen |
| INS-04 | qBittorrent Basic Auth | Empty key → Advanced → Add Basic Auth `admin` / `adminarr` | “Auth: Username & Password” | Not run |
| INS-05 | qBittorrent key validation | Empty key, no auth header | “Provide an API key or add Basic Auth below” | Not run |
| INS-06 | Field validation | Empty name, `ftp://x`, same alternative URL | “Required”, URL error, “Must differ from the primary URL” | Not run |
| INS-07 | Wrong key | `wrong` → Test, Save | “Error: …”; Save shows “Validation failed: …” | Not run |
| INS-08 | API key visibility | Eye icon | Shows / hides | Not run |
| INS-09 | Alternative URL failover | Primary `http://127.0.0.1:1`, alternative the real URL | Instance works through the alternative | Not run |
| INS-10 | Slow Instance Mode | Toggle, Save | Saved (90 s timeout) | Not run |
| INS-11 | Custom header | Add Header name/value, delete it | Header row listed and removed | Not run |
| INS-12 | Second instance | Add another Radarr (same lab URL, new name) | Instance selector appears on Movies | Not run |
| INS-13 | Edit instance | Tap row, rename, Save | New label in list | Not run |
| INS-14 | Delete instance | Trash → Delete | Removed; data screens reflect it | Not run |
| INS-15 | Missing instance | `/settings/instance/does-not-exist` | “Instance not found” + Go back | Not run |

## System Management (SYS)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| SYS-01 | Logs: ARR Logs | Logs | Info, warn, and error lines from the lab, newest first, plus a line per command run; source dropdown per instance; pull to refresh | Seen |
| SYS-02 | Logs: App Logs | Tab | Arrmate internal logs | Not run |
| SYS-03 | Logs: level filter | All / Info / Warn / Error / Debug | Filters the active tab; ARR Logs has one line each at Info, Warn, Error at startup | Not run |
| SYS-04 | Logs: copy row / copy all | Icons | “Log copied” / “All logs copied to clipboard” | Not run |
| SYS-05 | Logs: clear app logs | App Logs tab, clear icon | “App logs cleared” (icon hidden on ARR Logs) | Not run |
| SYS-06 | Logs: detail sheet | Tap row | Time, Level, Logger, Message; the error line shows an Exception | Not run |
| SYS-07 | Health | Open | Two warnings per app: the mocked download client and TorrentDay unavailable | Seen |
| SYS-08 | Health: Run health check | Icon | Progress bar, reload | Not run |
| SYS-09 | Connection Diagnostics | Open | Network summary, each endpoint `OK · Nms · v…`, last 20 request traces | Not run |
| SYS-10 | Diagnostics: rerun, Export report | Icons | Re-runs; share sheet with sanitized report (no API keys) | Not run |
| SYS-11 | System Overview | Open, pull to refresh | Radarr and Sonarr cards: version, library counts and size, three disk-space entries | Not run |
| SYS-12 | Quality Profiles | Open | Radarr and Sonarr sections with HD-1080p, Ultra-HD | Not run |
| SYS-13 | Minimum seeding days | Set 5, Save | Trailing “5d”; seeding warnings use it | Not run |
| SYS-14 | Version History | Open | GitHub releases, “Installed” badge | Not run |
| SYS-15 | Clear image cache | Tap | “Image cache cleared”; posters reload | Not run |
| SYS-16 | Reset app settings | Tap → Reset | “App settings reset to defaults”; theme, home tab, sorts reset; instances kept | Not run |

## Notifications (NTF)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| NTF-01 | Setup | Setup Notifications | Topic generated, notifications enabled | Not run |
| NTF-02 | Enable switch | Toggle | “Connected to ntfy.sh” / “Disconnected” | Not run |
| NTF-03 | Copy topic | Copy icon | “Topic copied to clipboard” | Not run |
| NTF-04 | Auto-configure | Auto-configure *arr instances | Results dialog; Radarr and Sonarr gain an ntfy notification (`GET /api/v3/notification`); running it again updates the existing one | Not run |
| NTF-05 | Event checkboxes | Grab, Import, Failure, Added, Deleted, File Deleted, Instance Update, Manual Interaction, Health Issues (+ Include Warnings, Health Restored) | Saved; pushed to instances on leave | Not run |
| NTF-06 | ntfy documentation link | Button | Browser | Not run |
| NTF-07 | Center: list | `/notifications` after a purge | Purge entry with type icon, “NEW” chip | Not run |
| NTF-08 | Center: tap | Tap card | Marked read | Not run |
| NTF-09 | Center: swipe | Swipe card | “Notification dismissed” | Not run |
| NTF-10 | Center: Mark all as read / Clear all | App bar | Snackbars; Clear asks for confirmation | Not run |
| NTF-11 | Live delivery | Publish to the topic on ntfy.sh | Notification appears in-app | Not run |

## Assistant (ASI)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| ASI-01 | Online mode | Menu → OpenCode Zen / Online Models | Free model selected | Not run |
| ASI-02 | Ask | “How do I add a movie?” | Answer grounded on the movies skill | Not run |
| ASI-03 | Local models | Download / Import / Local Models | Android native only; hidden elsewhere | Not run |
| ASI-04 | Send disabled | No model / while generating | Send disabled | Not run |

## Guided tour (TOU)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| TOU-01 | First run | Fresh install | Tour starts automatically | Not run |
| TOU-02 | Steps | Advance through all | Settings, instance form, Movies, Series, Calendar, Activity, Torrents, navigation | Not run |
| TOU-03 | Sample cards | Run tour with no instances | Inert sample cards and banner on every data screen | Not run |
| TOU-04 | Real data | Run tour with the lab instances | Real cards, no samples | Not run |
| TOU-05 | Skip | Skip mid-tour | Ends, goes to `/movies`, samples disappear, does not restart | Not run |

## Updates (UPD)

| ID | Control | Steps | Expected | Status |
| --- | --- | --- | --- | --- |
| UPD-01 | Update dialog | Android release build older than latest | “Nova Versão Disponível”, Mais Tarde / Atualizar Agora, download progress | Not run |
| UPD-02 | What's New | First launch after update | “What's New in v…”, Dismiss / View All Versions | Not run |

---

## Behavior gaps found while mapping

Things the code does differently from the in-app assistant skills or UI copy.
They are not covered by the rows above and need a product decision.

- `Minimum seeding days` says “0 disables the warning”, but the value is clamped to 1–60, so 0 is saved as 1.
- `/settings/system-management` is a router path, but the deep link validator rejects it.
- Health wiki URLs are shown as plain text, not as links.
- Series details have no Files, Extra files, or History section, unlike movie details. The providers exist; the screen does not use them.
- The episode sheet shows monitoring as read-only; monitoring is only on the season list.
- Manual import and torrent import cannot change the matched movie, episode, or quality.
- Torrents have no long-press or bulk actions.
- Import to Media Library scans the torrent's save path (`/downloads/radarr`), so the file list includes every completed download in that category, not only the selected torrent. qBittorrent's `content_path` would scope it to the torrent.
- The notification center does not navigate to the media on tap.
- The skills describe battery saver, polling interval, a test notification, topic sharing, an auto-update toggle, and a What's New tile; none of these exist in the UI.
- Discover's quality profile and root folder dropdowns keep a selection once options load. There is no clear control, so the “Please select a movie, quality profile, and root folder” snackbar cannot be reached from the UI (DIS-09).

## Media lab limits

The lab models the side effects the app depends on (see
[e2e-media-stack.md](e2e-media-stack.md)). It still does not model:

- Refresh, Rescan, and health-check commands: they only add a log line.
- Real indexers: every search returns the same synthetic releases per item, and Prowlarr search is static.
- Upgrades: a file is never replaced by a better grab; a second import simply overwrites the file record.
- Fixture downloads (Dune, Severance S01E09) never finish; they stall at 97% so the fixture queue stays stable. Restart the lab to reset their progress.
- Import exclusions are stored but not shown anywhere, matching the app, which has no exclusion screen.
