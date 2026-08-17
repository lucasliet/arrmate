# Arrmate: A Companion App for Radarr and Sonarr 📺

Arrmate is a comprehensive companion app designed to work seamlessly with Radarr
and Sonarr, offering a streamlined and user-friendly experience for managing
your media library. With Arrmate, you can easily browse, search, and manage your
movies and series, all in one convenient place. You can also monitor your
downloads with the integrated qBittorrent support. The app is built using
Flutter and utilizes the Riverpod state management library to ensure a smooth
and efficient user experience.

## 📦 Installation

To get started with Arrmate, follow these steps: Download the latest release
from the [releases page](https://github.com/lucasliet/arrmate/releases).

## 🚀 Features

- **Library Management**: Browse, search, filter, sort, batch select, and
  manage your movie and series libraries with a native mobile experience.
- **Content Discovery**: Search/add screen opened by the FAB on the Movies and
  Series tabs — it opens straight into that tab's media type and accepts a
  title, a TMDB/IMDb/TVDB ID, or a URL, with debounced lookup, sort, and a
  "Hide already added" filter.
- **Media Management**: Delete, monitor/unmonitor in batch, and purge movies or
  series from your library, plus remove individual media files with
  confirmation dialogs.
- **Import Exclusions**: When deleting a movie or series, optionally add it to
  the import exclusion list so it is never re-imported automatically.
- **Season Management (Sonarr)**: Run automatic and interactive season search,
  purge full seasons, and delete season files directly from season details.
- **Safer Purge Flow**: Purge detects cross-seed candidates and requires
  explicit per-torrent approval before deleting duplicates in qBittorrent, and
  it only clears the queue and torrents after the catalog deletion succeeds, so
  a failed purge leaves in-flight downloads untouched.
- **System Management**: A single screen (Settings → System → System Management)
  grouping server tools (logs, health, diagnostics, storage overview, quality
  profiles), the minimum-seeding-days guard, and app maintenance (version
  history, image-cache clearing, settings reset).
- **Download Client Integration**: Full qBittorrent support to view, pause,
  resume, and delete downloads, plus add new torrents via URL or file.
- **Torrent Import**: Import completed torrent files directly to your
  Radarr/Sonarr media library with file mapping and target selection.
- **Library Link Status**: See at a glance which torrents back an item in the
  library, which were downloaded outside of it, and which are orphans left
  behind after the movie/episode was removed — highlighted and filterable.
  Cross-seed copies inherit the link of the torrent Radarr/Sonarr grabbed
  instead of being flagged as orphans, and say so with a `Cross-seed` badge.
- **Media Torrents**: Movie, series and episode details list the torrents
  backing the item — cross-seed duplicates included — and open the torrent
  details from there, the reverse of jumping from a torrent to its library item.
- **Interactive Release Search**: Find and download specific torrents or NZBs
  directly from the app.
- **Activity & Queue Monitoring**: Track active downloads and historical events
  like grabs, imports, and failures.
- **Manual Import**: Match and import files from the queue with file selection
  and quality mapping.
- **Files & Metadata**: View detailed file information (quality, codecs, size)
  and extra files for movies and series.
- **Media History**: Browse movie-specific and series-specific historical events
  with filtering.
- **Edit Media**: Update monitoring, quality profiles, root folders, and series
  types with optional file moving.
- **Calendar Filters**: Filter the aggregated calendar by instance, media type,
  monitored, premieres, and hide specials, with a one-tap reset.
- **Connection Diagnostics**: Test every configured endpoint for reachability
  and latency, inspect recent request traces, and export a sanitized report.
- **System Overview**: View per-instance disk space and storage usage, library
  sizes, and server versions.
- **Slow Instance Mode**: Extended timeout support (90s) for remote or slow
  server connections.
- **Offline Indicator**: An explicit offline banner with the last-online
  timestamp so you know when data may be stale.
- **Notifications**: Receive real-time push notifications via
  [ntfy.sh](https://ntfy.sh) integration with **unique multi-device
  synchronization**, **automatic configuration**, and **background polling**
  (every 30 min) with optional Battery Saver mode, plus in-app purge event
  notifications for removed torrents.
- **Guided Onboarding**: Built-in setup tour with coach marks on first launch,
  with replay available at Settings → About → Getting Started. While no
  instance is configured the tour fills the library, calendar, and download
  screens with sample cards so every step has a visible target; the samples are
  purely visual and disappear as soon as the tour is finished or skipped.
- **Deep Linking**: Open the app straight to a movie, series, season, episode,
  calendar, activity, search, or settings screen via the `arrmate://` scheme.
- **What's New & Version History**: A changelog popup after each update, plus a
  browsable version history pulled from GitHub Releases.
- **Multi-Instance Support**: Manage multiple Radarr and Sonarr server instances
  simultaneously.
- **Advanced Monitoring**: View real-time system logs, health checks, and
  quality profiles.
- **AI Assistant**: On-device AI assistant powered by local LLMs (Gemma, Qwen)
  for help with app features, troubleshooting, and navigation guidance.
- **Auto-Updater**: Support for automatic and manual in-app updates via GitHub
  Releases.

## 🛠️ Tech Stack

- **Flutter**: Framework used to build the seamless and efficient native mobile
  experience.
- **Riverpod**: Utilized for robust and efficient state management throughout
  the application.
- **Dio**: Used for making high-performance HTTP requests to Radarr and Sonarr
  APIs.
- **SharedPreferences**: Employs local persistence for settings, filters, and
  notification state.
- **ntfluttery**: Client library for ntfy.sh push notifications.
- **Flutter Local Notifications**: Handles local push notifications for download
  and system events.
- **Go Router**: Utilizes a declarative routing system for smooth navigation
  between features.
- **MediaPipe LLM Inference**: Powers the on-device AI assistant with local
  model execution.
- **Package Info Plus & OTA Update**: Powering the automated in-app update
  system.

## 💻 Usage

To use Arrmate, follow these steps:

1. **Configure Connections**: Enter your Radarr, Sonarr and qBittorrent API keys
   and server URLs in the settings to sync your media library.
2. **Explore Media**: Browse through your movies and series with posters,
   metadata, and status indicators.
3. **Search & Filter**: Use the search functionality to find specific titles or
   filter content by availability and quality.
4. **Remote Management**: Update monitoring status, trigger searches, and manage
   your library settings directly from the app.

## 🔔 Push Notifications

Arrmate supports real-time push notifications via [ntfy.sh](https://ntfy.sh):

1. Open **Arrmate** > **Settings** > **Notifications**.
2. Tap **Setup Push Notifications** to generate your unique topic.
3. Tap *_Auto-configure _arr instances__ to automatically set up webhooks in all
   your connected Radarr/Sonarr servers.
4. **Done!** Arrmate uses a unique naming scheme `Arrmate (suffix)` to ensure
   multiple devices can coexist on the same server without overwriting each
   other's settings.

> [!TIP]
> Once notifications are enabled, any new instance you add to Arrmate will be
> **automatically configured** with the required webhooks.

## 🔗 Deep Links

Arrmate registers the `arrmate://` URI scheme (with a native Android
`intent-filter`) so external apps, shortcuts, or `adb` can jump straight to a
specific screen. Both the host form (`arrmate://movies/123`) and the
authority-less form (`arrmate:///movies/123`) are supported.

| Route | Example |
| --- | --- |
| Movie details | `arrmate:///movies/<id>` |
| Series details | `arrmate:///series/<id>` |
| Season details | `arrmate:///series/<id>/season/<n>` |
| Episode details | `arrmate:///series/<id>/season/<n>/episode/<id>` |
| Calendar | `arrmate:///calendar` |
| Activity | `arrmate:///activity` |
| Discover | `arrmate:///discover?type=movie` (or `type=series`; defaults to `movie`) |
| Search | `arrmate:///search?q=<term>&type=movie` |
| Settings (and sub-screens) | `arrmate:///settings`, `arrmate:///settings/system-management`, `arrmate:///settings/diagnostics`, `arrmate:///settings/system-overview`, `arrmate:///settings/version-history`, … |
| Instance editor | `arrmate:///settings/instance/<id>` |

Unsupported links are rejected rather than navigating with a zeroed identifier.

## 🤝 Contributing

To contribute to Arrmate, please follow these steps:

1. **Fork the Repository**: Fork the Arrmate repository using Git.
2. **Create a Branch**: Create a new branch for your feature or bug fix.
3. **Make Changes**: Make the necessary changes to the code.
4. **Submit a Pull Request**: Submit a pull request to the main repository.

## 📝 License

Arrmate is licensed under the [MIT License](./LICENSE).
