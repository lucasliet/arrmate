#!/usr/bin/env python3
"""Mock Radarr, Sonarr, Prowlarr, and qBittorrent for Arrmate end-to-end tests.

The four APIs share one in-memory library, so actions cascade the way they do
on a real stack:

- Grabbing a release (interactive or through a search command) adds a
  qBittorrent torrent, a queue item, and a `grabbed` history event. Grabbed
  torrents finish in about a minute, then import on their own: the movie or
  episodes gain a file, the queue item leaves, and an import event is recorded.
- Fixture downloads creep forward in real time and stall just before
  completion, so the fixture queue stays stable for a whole test pass.
- `ManualImport` writes files, clears the matching queue item, and records an
  import event. `/manualimport` lists the real files of the torrent or folder.
- Removing a queue item honors `removeFromClient`, `blocklist`, and
  `skipRedownload`. Deleting a movie or series drops its history, as Radarr
  and Sonarr do, so its torrents turn into orphans.
- `/calendar` honors `start`, `end`, and `unmonitored`.
- qBittorrent speaks the 5.x dialect: `stop`/`start`, `stoppedDL`/`stoppedUP`,
  the `stopped` add flag, persisted file priorities, and a timed recheck.

Credentials
    Radarr     X-Api-Key: arrmate-radarr     http://127.0.0.1:7878
    Sonarr     X-Api-Key: arrmate-sonarr     http://127.0.0.1:8989
    Prowlarr   X-Api-Key: arrmate-prowlarr   http://127.0.0.1:9696
    qBittorrent  admin:adminarr  or Bearer arrmate-qbit
                 http://127.0.0.1:8080
"""

from __future__ import annotations

import copy
import hashlib
import json
import re
import struct
import threading
import time
import zlib
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, unquote_plus, urlparse

RADARR_KEY = "arrmate-radarr"
SONARR_KEY = "arrmate-sonarr"
PROWLARR_KEY = "arrmate-prowlarr"
QBIT_USER = "admin"
QBIT_PASSWORD = "adminarr"
QBIT_BEARER = "arrmate-qbit"
QBIT_SID = "arrmate-lab"

LOCK = threading.Lock()
NOW = datetime.now(timezone.utc)

GRAB_SECONDS = 60
FIXTURE_RATE = 0.0001
FIXTURE_STALL_AT = 0.97
STALLED_MESSAGE = "The download is stalled with no connections"
RECHECK_SECONDS = 3
STOPPED_STATES = ("pausedDL", "pausedUP", "stoppedDL", "stoppedUP")
DOWNLOADING_STATES = ("downloading", "stalledDL", "metaDL", "queuedDL", "checkingDL", "forcedDL")
SEEDING_STATES = ("uploading", "stalledUP", "forcedUP", "queuedUP", "checkingUP")
AVAILABILITY_RANK = {"tba": 0, "announced": 1, "inCinemas": 2, "released": 3, "deleted": 0}


def now() -> datetime:
    """Wall-clock time, for events created while the lab runs."""
    return datetime.now(timezone.utc)


def iso(moment: datetime) -> str:
    """Return an ISO-8601 timestamp the Dart parsers accept."""
    return moment.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_time(value: str | None) -> datetime | None:
    """Parse the `start`/`end` query values the app sends.

    Dart's `toIso8601String` omits the offset for local times; like an *arr
    container running in UTC, those are read as UTC.
    """
    if not value:
        return None
    text = value.strip().replace("Z", "+00:00").replace(" ", "+")
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed


def flag(query: dict, name: str, default: bool) -> bool:
    """Read a boolean query parameter."""
    raw = (query.get(name) or [None])[0]
    if raw is None:
        return default
    return raw.lower() in ("true", "1", "yes")


def normalize(text: str) -> str:
    """Lowercase alphanumerics only, for title matching."""
    return re.sub(r"[^a-z0-9]", "", text.lower())


def quality(name: str = "Bluray-1080p", quality_id: int = 7, resolution: int = 1080) -> dict:
    """Build a Radarr/Sonarr quality object."""
    source = "bluray" if "bluray" in name.lower() or "remux" in name.lower() else "web"
    return {
        "quality": {
            "id": quality_id,
            "name": name,
            "source": source,
            "resolution": resolution,
        },
        "revision": {"version": 1, "real": 0, "isRepack": False},
    }


def quality_from_title(title: str) -> dict:
    """Guess the quality the way the *arr parsers would."""
    lowered = title.lower()
    if "2160" in lowered:
        return quality("Remux-2160p" if "remux" in lowered else "WEBDL-2160p", 31, 2160)
    if "720" in lowered:
        return quality("WEBDL-720p", 5, 720)
    if "web" in lowered:
        return quality("WEBDL-1080p", 3, 1080)
    return quality()


ENGLISH = {"id": 1, "name": "English"}
HD = quality()


def png(red: int, green: int, blue: int, width: int, height: int) -> bytes:
    """Build a solid-color PNG without third-party libraries."""

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    raw = b"".join(b"\x00" + bytes((red, green, blue)) * width for _ in range(height))
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


POSTER_CACHE: dict[tuple[int, int, int, int, int], bytes] = {}


def cover_bytes(seed: int, wide: bool) -> bytes:
    """Return a distinct poster or fanart for [seed]."""
    red = 40 + (seed * 47) % 180
    green = 50 + (seed * 29) % 160
    blue = 70 + (seed * 83) % 150
    size = (640, 360) if wide else (300, 450)
    key = (red, green, blue, size[0], size[1])
    cached = POSTER_CACHE.get(key)
    if cached is None:
        cached = png(red, green, blue, size[0], size[1])
        POSTER_CACHE[key] = cached
    return cached


def images_for(item_id: int, base: str) -> list[dict]:
    """Cover URLs that resolve on this mock, using the caller's host."""
    return [
        {
            "coverType": "poster",
            "url": f"/MediaCover/{item_id}/poster.jpg",
            "remoteUrl": f"{base}/MediaCover/{item_id}/poster.jpg",
        },
        {
            "coverType": "fanart",
            "url": f"/MediaCover/{item_id}/fanart.jpg",
            "remoteUrl": f"{base}/MediaCover/{item_id}/fanart.jpg",
        },
    ]


def media_file(file_id: int, name: str, folder: str, *, size: int = 4_000_000_000, added: datetime | None = None) -> dict:
    """Serialize a movie or episode file."""
    file_quality = quality_from_title(name)
    resolution = file_quality["quality"]["resolution"]
    return {
        "id": file_id,
        "relativePath": name,
        "path": f"{folder}/{name}",
        "size": size,
        "dateAdded": iso(added or NOW - timedelta(days=3)),
        "quality": file_quality,
        "languages": [ENGLISH],
        "customFormats": [{"id": 1, "name": "HDR"}] if resolution == 2160 else [],
        "customFormatScore": 100 if resolution == 2160 else 0,
        "releaseGroup": "LAB",
        "mediaInfo": {
            "audioCodec": "EAC3",
            "audioChannels": 5.1,
            "videoCodec": "x265" if resolution == 2160 else "x264",
            "resolution": "3840x2160" if resolution == 2160 else f"1920x{resolution}",
            "runTime": "2:35:00",
            "subtitles": "English",
        },
    }


def movie_record(
    movie_id: int,
    tmdb_id: int,
    title: str,
    year: int,
    overview: str,
    *,
    in_library: bool,
    has_file: bool = False,
    monitored: bool = True,
    status: str = "released",
    in_cinemas: datetime | None = None,
    digital: datetime | None = None,
    physical: datetime | None = None,
    genres: list[str] | None = None,
    studio: str = "Arrmate Pictures",
    runtime: int = 128,
    imdb: str | None = None,
    base: str = "http://127.0.0.1:7878",
) -> dict:
    """Serialize one movie the way Radarr's v3 resource does."""
    folder = f"{title} ({year})"
    record = {
        "id": movie_id if in_library else 0,
        "tmdbId": tmdb_id,
        "imdbId": imdb or f"tt{tmdb_id:07d}",
        "title": title,
        "sortTitle": title.lower(),
        "studio": studio,
        "year": year,
        "runtime": runtime,
        "overview": overview,
        "certification": "PG-13",
        "youTubeTrailerId": "arrmate",
        "originalLanguage": ENGLISH,
        "alternateTitles": [],
        "genres": genres or ["Science Fiction", "Drama"],
        "ratings": {
            "imdb": {"votes": 120000, "value": 8.1},
            "tmdb": {"votes": 8000, "value": 8.0},
        },
        "popularity": 80.0,
        "status": status,
        "minimumAvailability": "released",
        "monitored": monitored,
        "qualityProfileId": 1,
        "sizeOnDisk": 0,
        "hasFile": False,
        "path": f"/movies/{folder}" if in_library else None,
        "folderName": folder,
        "rootFolderPath": "/movies",
        "added": iso(NOW - timedelta(days=12)) if in_library else "0001-01-01T00:00:00Z",
        "inCinemas": iso(in_cinemas or datetime(year, 6, 1, tzinfo=timezone.utc)),
        "physicalRelease": iso(physical or datetime(year, 9, 1, tzinfo=timezone.utc)),
        "digitalRelease": iso(digital or datetime(year, 8, 15, tzinfo=timezone.utc)),
        "tags": [1] if in_library else [],
        "images": images_for(tmdb_id, base),
    }
    set_availability(record)
    if has_file:
        attach_movie_file(
            record,
            media_file(1000 + movie_id, f"{folder} Bluray-1080p.mkv", record["path"], size=8_000_000_000),
        )
    return record


def set_availability(movie: dict) -> None:
    """Derive `isAvailable` from status and minimum availability."""
    wanted = AVAILABILITY_RANK.get(movie.get("minimumAvailability") or "released", 3)
    movie["isAvailable"] = AVAILABILITY_RANK.get(movie.get("status") or "released", 0) >= wanted


def attach_movie_file(movie: dict, file: dict | None) -> None:
    """Point [movie] at [file], or clear its file when [file] is None."""
    movie["movieFile"] = file
    movie["hasFile"] = file is not None
    movie["sizeOnDisk"] = file["size"] if file else 0
    if file:
        file["movieId"] = movie["id"]


def lookup_season(number: int, episodes: int) -> dict:
    """Season stub for lookup results, which carry no files."""
    return {
        "seasonNumber": number,
        "monitored": True,
        "statistics": {
            "episodeCount": 0,
            "episodeFileCount": 0,
            "totalEpisodeCount": episodes,
            "percentOfEpisodes": 0,
            "sizeOnDisk": 0,
        },
    }


def series_record(
    series_id: int,
    tvdb_id: int,
    title: str,
    year: int,
    overview: str,
    *,
    in_library: bool,
    seasons: list[int],
    status: str = "continuing",
    network: str = "Apple TV+",
    imdb: str | None = None,
    base: str = "http://127.0.0.1:8989",
) -> dict:
    """Serialize one series the way Sonarr's v3 resource does.

    Library series get their statistics from [Lab.refresh_series].
    """
    folder = f"{title} ({year})"
    return {
        "id": series_id if in_library else 0,
        "title": title,
        "titleSlug": title.lower().replace(" ", "-"),
        "sortTitle": title.lower(),
        "tvdbId": tvdb_id,
        "tvMazeId": tvdb_id,
        "imdbId": imdb or f"tt{tvdb_id:07d}",
        "tmdbId": tvdb_id,
        "status": status,
        "seriesType": "standard",
        "path": f"/tv/{folder}" if in_library else None,
        "folder": folder,
        "qualityProfileId": 1,
        "rootFolderPath": "/tv",
        "certification": "TV-MA",
        "year": year,
        "runtime": 48,
        "airTime": "21:00",
        "ended": status == "ended",
        "seasonFolder": True,
        "useSceneNumbering": False,
        "added": iso(NOW - timedelta(days=20)) if in_library else "0001-01-01T00:00:00Z",
        "firstAired": iso(datetime(year, 2, 1, tzinfo=timezone.utc)),
        "monitored": True,
        "monitorNewItems": "all",
        "overview": overview,
        "network": network,
        "originalLanguage": ENGLISH,
        "alternateTitles": [],
        "seasons": [{"seasonNumber": number, "monitored": number > 0} for number in seasons],
        "tags": [1] if in_library else [],
        "genres": ["Drama", "Science Fiction"],
        "images": images_for(tvdb_id, base),
        "ratings": {"votes": 40000, "value": 8.4},
    }


def episode_record(
    episode_id: int,
    series_id: int,
    season_number: int,
    number: int,
    title: str,
    *,
    airs: datetime,
    monitored: bool = True,
) -> dict:
    """Serialize one episode without a file."""
    return {
        "id": episode_id,
        "seriesId": series_id,
        "tvdbId": 700000 + episode_id,
        "seasonNumber": season_number,
        "episodeNumber": number,
        "title": title,
        "overview": f"{title} moves the season forward.",
        "airDate": airs.date().isoformat(),
        "airDateUtc": iso(airs),
        "runtime": 48,
        "hasFile": False,
        "monitored": monitored,
        "episodeFileId": 0,
        "episodeFile": None,
    }


def release_record(
    guid: str,
    title: str,
    *,
    indexer: str,
    indexer_id: int,
    rejected: bool = False,
    rejection: str = "Release is below the quality cutoff",
    seeders: int = 40,
    size: int = 6_000_000_000,
    full_season: bool = False,
    episode_numbers: list[int] | None = None,
    season_number: int | None = None,
    age: int = 2,
    freeleech: bool = True,
) -> dict:
    """Serialize an interactive-search release attributed to Prowlarr."""
    infohash = hashlib.sha1(guid.encode()).hexdigest()
    release_quality = quality_from_title(title)
    return {
        "guid": guid,
        "title": title,
        "size": size,
        "link": f"http://127.0.0.1:9696/download/{guid}",
        "indexer": f"{indexer} (Prowlarr)",
        "indexerId": indexer_id,
        "seeders": seeders,
        "leechers": 3,
        "protocol": "torrent",
        "rejected": rejected,
        "rejections": [rejection] if rejected else [],
        "age": age,
        "ageHours": age * 24.0,
        "publishDate": iso(NOW - timedelta(days=age)),
        "indexerFlags": ["freeleech"] if freeleech and not rejected else [],
        "infoUrl": f"http://127.0.0.1:9696/info/{guid}",
        "downloadUrl": f"magnet:?xt=urn:btih:{infohash}",
        "infoHash": infohash,
        "customFormatScore": 50 if release_quality["quality"]["resolution"] == 2160 else 0,
        "qualityWeight": release_quality["quality"]["resolution"] // 10,
        "releaseWeight": 10,
        "languages": [ENGLISH],
        "customFormats": [{"id": 1, "name": "HDR"}] if release_quality["quality"]["resolution"] == 2160 else [],
        "mappedEpisodeNumbers": episode_numbers or [],
        "mappedSeasonNumber": season_number,
        "seasonNumber": season_number,
        "fullSeason": full_season,
        "episodeRequested": bool(episode_numbers) and not full_season,
        "quality": release_quality,
    }


SEVERANCE_S1 = [
    "Good News About Hell",
    "Half Loop",
    "In Perpetuity",
    "The You You Are",
    "The Grim Barbarity of Optics and Design",
    "Hide and Seek",
    "Defiant Jazz",
    "What's for Dinner?",
    "The We We Are",
]
SEVERANCE_S2 = [
    "Hello, Ms. Cobel",
    "Goodbye, Mrs. Selvig",
    "Who Is Alive?",
    "Woe's Hollow",
    "Trojan's Horse",
    "Attila",
    "Chikhai Bardo",
    "Sweet Vitriol",
    "The After Hours",
    "Cold Harbor",
]
THE_BEAR_S1 = [
    "System",
    "Hands",
    "Brigade",
    "Dogs",
    "Sheridan",
    "Ceres",
    "Review",
    "Braciole",
]
SHOGUN_S1 = [
    "Anjin",
    "Servants of Two Masters",
    "Tomorrow Is Tomorrow",
    "The Eightfold Fence",
    "Broken to the Fist",
    "Ladies of the Willow World",
    "A Stick of Time",
    "The Abyss of Life",
    "Crimson Sky",
    "A Dream of a Dream",
]


class Lab:
    """In-memory library shared by every mocked service."""

    def __init__(self) -> None:
        self.next_ids: dict[str, int] = {
            "movie": 10,
            "series": 10,
            "history": 0,
            "queue": 0,
            "command": 0,
            "file": 6000,
            "episode": 9000,
            "log": 0,
            "notification": {"radarr": 0, "sonarr": 0},
        }
        self.notifications: dict[str, list[dict]] = {"radarr": [], "sonarr": []}
        self.commands: dict[int, dict] = {}
        self.blocklist: list[dict] = []
        self.exclusions: dict[str, set[int]] = {"radarr": set(), "sonarr": set()}
        self.logs: dict[str, list[dict]] = {"radarr": [], "sonarr": []}
        self.release_meta: dict[str, dict] = {}
        self.download_meta: dict[str, dict] = {}
        self.sim: dict[str, dict] = {}
        self.files: dict[str, list[dict]] = {}
        self.last_tick = time.monotonic()

        self._movies()
        self._series()
        self._downloads()
        for series_id in self.series:
            self.refresh_series(series_id)
        for role in ("radarr", "sonarr"):
            app = "Radarr" if role == "radarr" else "Sonarr"
            self.log(role, "info", "Bootstrap", f"{app} starting with the Arrmate media lab library.", when=NOW - timedelta(minutes=5))
            self.log(
                role,
                "warn",
                "IndexerStatusService",
                "Indexer TorrentDay (Prowlarr) is temporarily disabled due to recent failures.",
                when=NOW - timedelta(minutes=3),
            )
            self.log(
                role,
                "error",
                "DownloadedItemsImportService",
                "Import failed for a download that no longer exists in the client.",
                when=NOW - timedelta(minutes=2),
                exception="System.IO.FileNotFoundException: Could not find file '/downloads/radarr/Gone.mkv'.",
            )

    # Fixtures ---------------------------------------------------------------

    def _movies(self) -> None:
        self.movies: dict[int, dict] = {}
        for record in (
            movie_record(
                1,
                438631,
                "Dune",
                2021,
                "Paul Atreides arrives on Arrakis and learns the desert keeps its own secrets.",
                in_library=True,
                imdb="tt1160419",
                has_file=True,
                genres=["Science Fiction", "Adventure"],
                runtime=155,
            ),
            movie_record(
                2,
                603,
                "The Matrix",
                1999,
                "A hacker discovers the world he knows is a simulation and chooses the red pill.",
                in_library=True,
                imdb="tt0133093",
                has_file=True,
                genres=["Action", "Science Fiction"],
                runtime=136,
            ),
            movie_record(
                3,
                329865,
                "Arrival",
                2016,
                "A linguist tries to understand visitors whose language rewrites time.",
                in_library=True,
                imdb="tt2543164",
                genres=["Drama", "Science Fiction"],
                runtime=116,
            ),
            movie_record(
                4,
                872585,
                "Oppenheimer",
                2023,
                "A physicist builds the weapon that ends one war and starts another kind of fear.",
                in_library=True,
                imdb="tt15398776",
                status="inCinemas",
                in_cinemas=NOW - timedelta(days=5),
                digital=NOW + timedelta(days=30),
                physical=NOW + timedelta(days=70),
                genres=["Drama", "History"],
                runtime=180,
            ),
        ):
            self.movies[record["id"]] = record
        self.lookup_movies = [
            movie_record(
                0,
                27205,
                "Inception",
                2010,
                "A thief enters dreams to plant an idea and risks losing the exit.",
                in_library=False,
                imdb="tt1375666",
                genres=["Action", "Science Fiction"],
                runtime=148,
            ),
            movie_record(
                0,
                335984,
                "Blade Runner 2049",
                2017,
                "A replicant hunts a secret that could change what it means to be human.",
                in_library=False,
                imdb="tt1856101",
                genres=["Science Fiction", "Mystery"],
                runtime=164,
            ),
        ]

    def _series(self) -> None:
        self.series: dict[int, dict] = {}
        self.episodes: dict[int, list[dict]] = {}
        severance = series_record(
            1,
            371980,
            "Severance",
            2022,
            "Office workers split their memories between the desk and the life outside.",
            in_library=True,
            imdb="tt11280740",
            seasons=[0, 1, 2],
        )
        bear = series_record(
            2,
            393189,
            "The Bear",
            2022,
            "A fine-dining chef inherits a Chicago sandwich shop and the family that runs it.",
            in_library=True,
            imdb="tt14452776",
            seasons=[1],
            status="ended",
            network="FX",
        )
        self.series = {1: severance, 2: bear}
        premiere = datetime(2022, 2, 18, 2, 0, tzinfo=timezone.utc)
        severance_episodes = [
            episode_record(10, 1, 0, 1, "Main Titles", airs=NOW + timedelta(days=6), monitored=False),
        ]
        for index, title in enumerate(SEVERANCE_S1):
            severance_episodes.append(
                episode_record(11 + index, 1, 1, index + 1, title, airs=premiere + timedelta(weeks=index))
            )
        for index, title in enumerate(SEVERANCE_S2):
            severance_episodes.append(
                episode_record(31 + index, 1, 2, index + 1, title, airs=NOW + timedelta(days=4, weeks=index))
            )
        self.episodes[1] = severance_episodes
        for episode in severance_episodes[1:5]:
            self._attach_episode_file(1, [episode], f"Severance.S01E{episode['episodeNumber']:02d}.1080p.ATVP.WEB-DL.mkv", NOW - timedelta(days=30))
        bear_premiere = datetime(2022, 6, 23, 4, 0, tzinfo=timezone.utc)
        bear_episodes = [
            episode_record(21 + index, 2, 1, index + 1, title, airs=bear_premiere)
            for index, title in enumerate(THE_BEAR_S1)
        ]
        self.episodes[2] = bear_episodes
        for episode in bear_episodes:
            self._attach_episode_file(2, [episode], f"The.Bear.S01E{episode['episodeNumber']:02d}.1080p.HULU.WEB-DL.mkv", NOW - timedelta(days=60))
        self.lookup_series = [
            {
                **series_record(
                    0,
                    417742,
                    "Shogun",
                    2024,
                    "A shipwrecked sailor becomes a pawn in a war for feudal Japan.",
                    in_library=False,
                    imdb="tt2788316",
                    seasons=[1],
                    status="ended",
                    network="FX",
                ),
                "seasons": [lookup_season(1, len(SHOGUN_S1))],
                "statistics": {
                    "seasonCount": 1,
                    "episodeCount": 0,
                    "episodeFileCount": 0,
                    "totalEpisodeCount": len(SHOGUN_S1),
                    "percentOfEpisodes": 0,
                    "sizeOnDisk": 0,
                },
            }
        ]

    def _downloads(self) -> None:
        self.torrents: list[dict] = []
        self.history: list[dict] = []
        self.series_history: list[dict] = []
        self.queue: list[dict] = []
        self.series_queue: list[dict] = []

        dune_old, dune_new = "5" * 40, "c" * 40
        matrix, matrix_cross = "a" * 40, "b" * 40
        arrival_failed, arrival = "6" * 40, "d" * 40
        orphan, broken = "e" * 40, "f" * 40
        bear_pack, severance_pack = "4" * 40, "3" * 40
        s01e01, s01e05, s01e09 = "9" * 40, "7" * 40, "8" * 40

        self.add_torrent(dune_new, "Dune 2021 Remux-2160p", state="downloading", progress=0.42, category="radarr", size=24_000_000_000, added=NOW - timedelta(hours=3))
        self.add_torrent(matrix, "The Matrix 1999 Bluray-1080p", state="uploading", progress=1, category="radarr", added=NOW - timedelta(days=6), seeding_days=5)
        self.add_torrent(matrix_cross, "The Matrix 1999 Bluray-1080p", state="uploading", progress=1, category="cross-seed", tags="cross-seed", added=NOW - timedelta(days=4), seeding_days=4)
        self.add_torrent(arrival, "Arrival 2016 WEBDL-1080p", state="stoppedUP", progress=1, category="radarr", added=NOW - timedelta(hours=20), seeding_days=0)
        self.add_torrent(broken, "Broken Sample WEBDL-720p", state="error", progress=0.05, category="radarr", added=NOW - timedelta(days=9))
        self.add_torrent(orphan, "Unrelated Concert Bootleg 2020", state="uploading", progress=1, category="", added=NOW - timedelta(days=40), seeding_days=39)
        self.add_torrent(s01e01, "Severance S01E01 Good News About Hell", state="uploading", progress=1, category="sonarr", size=1_500_000_000, added=NOW - timedelta(days=8), seeding_days=7)
        self.add_torrent(s01e09, "Severance S01E09 The We We Are", state="downloading", progress=0.6, category="sonarr", size=1_500_000_000, added=NOW - timedelta(hours=2))
        self.add_torrent(s01e05, "Severance S01E05 The Grim Barbarity of Optics and Design", state="stalledDL", progress=0.3, category="sonarr", size=1_500_000_000, added=NOW - timedelta(days=1))

        self.add_history("radarr", "grabbed", "Dune 2021 Bluray-1080p", movie_id=1, download_id=dune_old, when=NOW - timedelta(days=30))
        self.add_history("radarr", "downloadFolderImported", "Dune 2021 Bluray-1080p", movie_id=1, download_id=dune_old, when=NOW - timedelta(days=29))
        self.add_history(
            "radarr",
            "movieFileRenamed",
            "Dune (2021) Bluray-1080p.mkv",
            movie_id=1,
            download_id=None,
            when=NOW - timedelta(days=20),
            data={"sourcePath": "/movies/Dune (2021)/Dune.2021.1080p.BluRay.mkv", "path": "/movies/Dune (2021)/Dune (2021) Bluray-1080p.mkv"},
        )
        self.add_history("radarr", "grabbed", "Dune 2021 Remux-2160p", movie_id=1, download_id=dune_new, when=NOW - timedelta(hours=3))
        self.add_history("radarr", "grabbed", "The Matrix 1999 Bluray-1080p", movie_id=2, download_id=matrix, when=NOW - timedelta(days=6))
        self.add_history("radarr", "downloadFolderImported", "The Matrix 1999 Bluray-1080p", movie_id=2, download_id=matrix, when=NOW - timedelta(days=5))
        self.add_history("radarr", "grabbed", "Arrival 2016 HDTV-720p", movie_id=3, download_id=arrival_failed, when=NOW - timedelta(days=2))
        self.add_history(
            "radarr",
            "downloadFailed",
            "Arrival 2016 HDTV-720p",
            movie_id=3,
            download_id=arrival_failed,
            when=NOW - timedelta(days=1, hours=2),
            data={"message": "Download was stalled with no connections"},
        )
        self.add_history("radarr", "grabbed", "Arrival 2016 WEBDL-1080p", movie_id=3, download_id=arrival, when=NOW - timedelta(hours=20))
        self.add_history(
            "radarr",
            "downloadIgnored",
            "Oppenheimer 2023 CAM",
            movie_id=4,
            download_id=None,
            when=NOW - timedelta(days=4),
            data={"message": "Manually ignored"},
        )

        bear_episode_ids = [episode["id"] for episode in self.episodes[2]]
        for episode_id in bear_episode_ids:
            self.add_history("sonarr", "grabbed", "The Bear S01 1080p HULU WEB-DL", series_id=2, episode_id=episode_id, download_id=bear_pack, when=NOW - timedelta(days=61))
        for episode_id in bear_episode_ids:
            self.add_history("sonarr", "downloadFolderImported", "The Bear S01 1080p HULU WEB-DL", series_id=2, episode_id=episode_id, download_id=bear_pack, when=NOW - timedelta(days=60))
        self.add_history(
            "sonarr",
            "downloadIgnored",
            "The Bear S01E01 720p HDTV",
            series_id=2,
            episode_id=21,
            download_id=None,
            when=NOW - timedelta(days=59),
            data={"message": "Manually ignored"},
        )
        self.add_history("sonarr", "grabbed", "Severance S01E01 Good News About Hell", series_id=1, episode_id=11, download_id=s01e01, when=NOW - timedelta(days=8))
        self.add_history("sonarr", "downloadFolderImported", "Severance S01E01 Good News About Hell", series_id=1, episode_id=11, download_id=s01e01, when=NOW - timedelta(days=7))
        for episode_id in (12, 13, 14):
            self.add_history("sonarr", "grabbed", "Severance S01E02-E04 1080p ATVP WEB-DL", series_id=1, episode_id=episode_id, download_id=severance_pack, when=NOW - timedelta(days=31))
            self.add_history("sonarr", "downloadFolderImported", "Severance S01E02-E04 1080p ATVP WEB-DL", series_id=1, episode_id=episode_id, download_id=severance_pack, when=NOW - timedelta(days=30))
        self.add_history("sonarr", "grabbed", "Severance S01E05 The Grim Barbarity of Optics and Design", series_id=1, episode_id=15, download_id=s01e05, when=NOW - timedelta(days=1))
        self.add_history("sonarr", "grabbed", "Severance S01E09 The We We Are", series_id=1, episode_id=19, download_id=s01e09, when=NOW - timedelta(hours=2))

        self.add_queue("radarr", "Dune 2021 Remux-2160p", movie_id=1, download_id=dune_new)
        self.add_queue(
            "radarr",
            "Arrival 2016 WEBDL-1080p",
            movie_id=3,
            download_id=arrival,
            tracked="warning",
            state="importPending",
            messages=[
                {
                    "title": "Arrival 2016 WEBDL-1080p",
                    "messages": ["Found matching movie via grab history, but release was matched to movie by ID. Manual Import required."],
                }
            ],
        )
        self.add_queue("sonarr", "Severance S01E09 The We We Are", series_id=1, episode_ids=[19], download_id=s01e09)
        self.add_queue("sonarr", "Severance S01E05 The Grim Barbarity of Optics and Design", series_id=1, episode_ids=[15], download_id=s01e05)
        self.sync_queues()

    # Helpers ----------------------------------------------------------------

    def next_id(self, kind: str) -> int:
        self.next_ids[kind] += 1
        return self.next_ids[kind]

    def log(self, role: str, level: str, component: str, message: str, *, when: datetime | None = None, exception: str | None = None) -> None:
        entry = {
            "id": self.next_id("log"),
            "time": iso(when or now()),
            "level": level,
            "logger": component,
            "message": message,
        }
        if exception:
            entry["exception"] = exception
            entry["exceptionType"] = exception.split(":", 1)[0]
        self.logs[role].insert(0, entry)

    def files_for(self, name: str, size: int, category: str) -> list[dict]:
        """Lay out the files a release of [name] would carry."""
        if re.search(r"S\d{2}E\d{2}", name, re.I) or category == "sonarr" and not re.search(r"S\d{2}(?!E)", name, re.I):
            return [{"name": f"{name}.mkv", "size": size}]
        if category == "sonarr":
            return [{"name": f"{name}/{name}.mkv", "size": size}]
        if not category:
            tracks = ["01 - Opening", "02 - Interlude", "03 - Encore"]
            each = size // len(tracks)
            return [{"name": f"{name}/{track}.flac", "size": each} for track in tracks]
        return [
            {"name": f"{name}/{name}.mkv", "size": size - 60_000_000 - 90_000},
            {"name": f"{name}/Sample/{name}-sample.mkv", "size": 60_000_000},
            {"name": f"{name}/{name}.en.srt", "size": 90_000},
        ]

    def add_torrent(
        self,
        infohash: str,
        name: str,
        *,
        state: str,
        progress: float,
        category: str,
        size: int = 6_000_000_000,
        tags: str = "",
        save_path: str | None = None,
        added: datetime | None = None,
        seeding_days: float = 0,
        auto: bool = False,
        files: list[dict] | None = None,
        front: bool = False,
    ) -> dict:
        save = save_path or f"/downloads/{category or 'manual'}"
        layout = files or self.files_for(name, size, category)
        self.files[infohash] = [
            {
                "index": index,
                "name": item["name"],
                "size": item["size"],
                "progress": progress,
                "priority": 1,
                "is_seed": progress >= 1,
                "availability": 1 if progress >= 1 else round(0.5 + progress / 2, 3),
                "piece_range": [0, 1],
            }
            for index, item in enumerate(layout)
        ]
        total = sum(item["size"] for item in layout)
        added_on = added or now()
        torrent = {
            "hash": infohash,
            "infohash_v1": infohash,
            "name": name,
            "size": total,
            "total_size": total,
            "progress": progress,
            "dlspeed": 0,
            "upspeed": 0,
            "eta": 8640000,
            "ratio": 0,
            "state": state,
            "category": category,
            "tags": ", ".join(item for item in ("arrmate", tags) if item),
            "save_path": save,
            "content_path": f"{save}/{layout[0]['name'].split('/')[0]}",
            "num_seeds": 12,
            "num_leechs": 3,
            "num_complete": 40,
            "num_incomplete": 6,
            "downloaded": int(total * progress),
            "uploaded": 0,
            "amount_left": int(total * (1 - progress)),
            "added_on": int(added_on.timestamp()),
            "completion_on": int((added_on + timedelta(hours=1)).timestamp()) if progress >= 1 else -1,
            "seeding_time": int(seeding_days * 86_400),
            "time_active": int(seeding_days * 86_400) + 3_600,
            "priority": 0 if progress >= 1 else 1,
            "tracker": "udp://tracker.arrmate.lab:1337/announce",
            "magnet_uri": f"magnet:?xt=urn:btih:{infohash}&dn={name.replace(' ', '+')}",
        }
        self.sim[infohash] = {
            "auto": auto,
            "speed": max(1, total // GRAB_SECONDS) if auto else max(1, int(total * FIXTURE_RATE)),
        }
        self.apply_state(torrent, state)
        if front:
            self.torrents.insert(0, torrent)
        else:
            self.torrents.append(torrent)
        return torrent

    def apply_state(self, torrent: dict, state: str) -> None:
        """Set [state] and the speeds, ETA, and ratio that go with it."""
        torrent["state"] = state
        sim = self.sim.get(torrent["hash"], {})
        total = torrent["total_size"]
        if state in ("downloading", "forcedDL"):
            torrent["dlspeed"] = sim.get("speed", 4_000_000)
            torrent["upspeed"] = 150_000
            torrent["eta"] = int(total * (1 - torrent["progress"]) / max(torrent["dlspeed"], 1))
        elif state in ("uploading", "forcedUP"):
            torrent["dlspeed"] = 0
            torrent["upspeed"] = 350_000
            torrent["eta"] = 8640000
        else:
            torrent["dlspeed"] = 0
            torrent["upspeed"] = 0
            torrent["eta"] = 8640000
        if torrent["progress"] >= 1 and torrent["uploaded"] == 0:
            torrent["uploaded"] = int(total * min(4, 0.3 + torrent["seeding_time"] / 86_400 * 0.25))
        torrent["ratio"] = round(torrent["uploaded"] / max(torrent["downloaded"], 1), 3)

    def torrent(self, infohash: str | None) -> dict | None:
        if not infohash:
            return None
        wanted = infohash.lower()
        return next((item for item in self.torrents if item["hash"] == wanted), None)

    def remove_torrents(self, hashes: set[str]) -> None:
        wanted = {item.lower() for item in hashes}
        self.torrents = [item for item in self.torrents if item["hash"] not in wanted]
        for infohash in wanted:
            self.files.pop(infohash, None)
            self.sim.pop(infohash, None)

    def add_history(
        self,
        role: str,
        event_type: str,
        title: str,
        *,
        movie_id: int | None = None,
        series_id: int | None = None,
        episode_id: int | None = None,
        download_id: str | None,
        when: datetime | None = None,
        data: dict | None = None,
    ) -> dict:
        event = {
            "id": self.next_id("history"),
            "eventType": event_type,
            "date": iso(when or now()),
            "sourceTitle": title,
            "quality": quality_from_title(title),
            "languages": [ENGLISH],
            "customFormats": [],
            "customFormatScore": 0,
            "qualityCutoffNotMet": False,
            "downloadId": download_id.upper() if download_id else None,
            "data": {
                "indexer": "1337x (Prowlarr)",
                "downloadClient": "qBittorrent",
                "downloadClientName": "qBittorrent",
                "releaseGroup": "LAB",
                **(data or {}),
            },
        }
        if role == "radarr":
            event["movieId"] = movie_id
            self.history.append(event)
        else:
            event["seriesId"] = series_id
            event["episodeId"] = episode_id
            self.series_history.append(event)
        return event

    def add_queue(
        self,
        role: str,
        title: str,
        *,
        movie_id: int | None = None,
        series_id: int | None = None,
        episode_ids: list[int] | None = None,
        download_id: str,
        tracked: str = "ok",
        state: str = "downloading",
        messages: list[dict] | None = None,
    ) -> dict:
        episode_ids = episode_ids or []
        season_number = None
        if role == "sonarr" and episode_ids:
            episode = self.episode(episode_ids[0])
            season_number = episode["seasonNumber"] if episode else None
        item = {
            "id": self.next_id("queue"),
            "title": title,
            "indexer": "1337x (Prowlarr)",
            "added": iso(now()),
            "quality": quality_from_title(title),
            "languages": [ENGLISH],
            "customFormats": [],
            "customFormatScore": 0,
            "status": "queued",
            "trackedDownloadStatus": tracked,
            "trackedDownloadState": state,
            "statusMessages": messages or [],
            "errorMessage": None,
            "downloadId": download_id.upper(),
            "protocol": "torrent",
            "downloadClient": "qBittorrent",
            "downloadClientHasPostImportCategory": False,
            "outputPath": f"/downloads/{role}/{title}",
            "size": 0,
            "sizeleft": 0,
        }
        if role == "radarr":
            item["movieId"] = movie_id
            self.queue.insert(0, item)
        else:
            item["seriesId"] = series_id
            item["episodeId"] = episode_ids[0] if episode_ids else None
            item["seasonNumber"] = season_number
            item["episodeHasFile"] = False
            self.series_queue.insert(0, item)
        self.download_meta[download_id.upper()] = {
            "role": role,
            "title": title,
            "movie_id": movie_id,
            "series_id": series_id,
            "episode_ids": episode_ids,
        }
        return item

    def episode(self, episode_id: int) -> dict | None:
        for episodes in self.episodes.values():
            for episode in episodes:
                if episode["id"] == episode_id:
                    return episode
        return None

    def _attach_episode_file(self, series_id: int, episodes: list[dict], name: str, added: datetime | None = None, download_id: str | None = None) -> dict:
        series = self.series[series_id]
        season_number = episodes[0]["seasonNumber"]
        folder = f"{series['path']}/Season {season_number:02d}" if series.get("seasonFolder", True) else series["path"]
        file = media_file(self.next_id("file"), name, folder, size=1_500_000_000, added=added)
        file["seriesId"] = series_id
        file["seasonNumber"] = season_number
        if download_id:
            file["downloadId"] = download_id
        for episode in episodes:
            episode["hasFile"] = True
            episode["episodeFileId"] = file["id"]
            episode["episodeFile"] = file
        return file

    def refresh_series(self, series_id: int) -> None:
        """Recompute season and series statistics from the episode list."""
        series = self.series.get(series_id)
        if series is None:
            return
        episodes = self.episodes.get(series_id, [])
        current = now()
        by_number = {season["seasonNumber"]: season for season in series.get("seasons", [])}
        for number in {episode["seasonNumber"] for episode in episodes}:
            by_number.setdefault(number, {"seasonNumber": number, "monitored": number > 0})
        totals = {"episodeCount": 0, "episodeFileCount": 0, "totalEpisodeCount": 0, "sizeOnDisk": 0}
        seasons = []
        upcoming: list[datetime] = []
        aired: list[datetime] = []
        for number in sorted(by_number):
            season = by_number[number]
            in_season = [episode for episode in episodes if episode["seasonNumber"] == number]
            size = sum({episode["episodeFileId"]: episode["episodeFile"]["size"] for episode in in_season if episode.get("episodeFile")}.values())
            files = sum(1 for episode in in_season if episode.get("hasFile"))
            counted = sum(
                1
                for episode in in_season
                if episode.get("hasFile")
                or (episode.get("monitored") and parse_time(episode["airDateUtc"]) <= current)
            )
            stats = {
                "episodeCount": counted,
                "episodeFileCount": files,
                "totalEpisodeCount": len(in_season),
                "sizeOnDisk": size,
                "percentOfEpisodes": round(files / counted * 100, 1) if counted else 0,
            }
            for episode in in_season:
                airs = parse_time(episode["airDateUtc"])
                if airs > current and episode.get("monitored"):
                    upcoming.append(airs)
                elif airs <= current:
                    aired.append(airs)
            in_season_dates = [parse_time(episode["airDateUtc"]) for episode in in_season]
            future = [moment for moment in in_season_dates if moment > current]
            past = [moment for moment in in_season_dates if moment <= current]
            if future:
                stats["nextAiring"] = iso(min(future))
            if past:
                stats["previousAiring"] = iso(max(past))
            seasons.append({"seasonNumber": number, "monitored": season.get("monitored", number > 0), "statistics": stats})
            if number > 0:
                for key in totals:
                    totals[key] += stats[key]
        series["seasons"] = seasons
        series["statistics"] = {
            **totals,
            "seasonCount": sum(1 for season in seasons if season["seasonNumber"] > 0),
            "percentOfEpisodes": round(totals["episodeFileCount"] / totals["episodeCount"] * 100, 1) if totals["episodeCount"] else 0,
        }
        series["nextAiring"] = iso(min(upcoming)) if upcoming else None
        series["previousAiring"] = iso(max(aired)) if aired else None

    # Releases and grabs -----------------------------------------------------

    def _register(self, release: dict, **meta) -> dict:
        self.release_meta[release["guid"]] = {"title": release["title"], "size": release["size"], **meta}
        if any(entry["sourceTitle"] == release["title"] for entry in self.blocklist):
            release["rejected"] = True
            release["rejections"] = ["Release is blocklisted"]
            release["indexerFlags"] = []
        return release

    def movie_releases(self, movie_id: int) -> list[dict]:
        movie = self.movies.get(movie_id)
        title = movie["title"] if movie else "Unknown"
        year = movie["year"] if movie else 2024
        releases = [
            release_record(f"movie-{movie_id}-1080", f"{title} {year} Bluray-1080p", indexer="1337x", indexer_id=1, size=9_000_000_000),
            release_record(f"movie-{movie_id}-2160", f"{title} {year} Remux-2160p", indexer="TorrentDay", indexer_id=2, seeders=8, size=48_000_000_000, age=14, freeleech=False),
            release_record(f"movie-{movie_id}-web", f"{title} {year} WEBDL-1080p", indexer="1337x", indexer_id=1, seeders=120, size=6_500_000_000, age=30),
            release_record(f"movie-{movie_id}-720", f"{title} {year} WEBDL-720p", indexer="EZTV", indexer_id=3, rejected=True, seeders=2, size=2_000_000_000),
        ]
        return [self._register(release, role="radarr", movie_id=movie_id) for release in releases]

    def episode_releases(self, episode_id: int) -> list[dict]:
        episode = self.episode(episode_id)
        if episode is None:
            return []
        series = self.series.get(episode["seriesId"]) or {"title": "Unknown"}
        code = f"S{episode['seasonNumber']:02d}E{episode['episodeNumber']:02d}"
        name = f"{series['title']} {code} {episode['title']}"
        releases = [
            release_record(f"episode-{episode_id}-1080", f"{name} 1080p WEB-DL", indexer="1337x", indexer_id=1, size=1_500_000_000, episode_numbers=[episode["episodeNumber"]], season_number=episode["seasonNumber"]),
            release_record(f"episode-{episode_id}-2160", f"{name} 2160p WEB-DL", indexer="TorrentDay", indexer_id=2, seeders=9, size=5_000_000_000, episode_numbers=[episode["episodeNumber"]], season_number=episode["seasonNumber"], freeleech=False),
            release_record(f"episode-{episode_id}-720", f"{name} 720p HDTV", indexer="EZTV", indexer_id=3, rejected=True, seeders=2, size=700_000_000, episode_numbers=[episode["episodeNumber"]], season_number=episode["seasonNumber"]),
        ]
        return [self._register(release, role="sonarr", series_id=episode["seriesId"], episode_ids=[episode_id]) for release in releases]

    def season_releases(self, series_id: int, season_number: int) -> list[dict]:
        series = self.series.get(series_id) or {"title": "Unknown"}
        in_season = [episode for episode in self.episodes.get(series_id, []) if episode["seasonNumber"] == season_number]
        aired = [episode for episode in in_season if parse_time(episode["airDateUtc"]) <= now()]
        ids = [episode["id"] for episode in aired or in_season]
        numbers = [episode["episodeNumber"] for episode in aired or in_season]
        prefix = f"{series['title']} S{season_number:02d}"
        releases = [
            release_record(f"season-{series_id}-{season_number}-1080", f"{prefix} 1080p WEB-DL", indexer="1337x", indexer_id=1, size=1_500_000_000 * max(1, len(ids)), full_season=True, episode_numbers=numbers, season_number=season_number),
            release_record(f"season-{series_id}-{season_number}-2160", f"{prefix} 2160p WEB-DL", indexer="TorrentDay", indexer_id=2, seeders=6, size=5_000_000_000 * max(1, len(ids)), full_season=True, episode_numbers=numbers, season_number=season_number, freeleech=False),
        ]
        registered = [self._register(release, role="sonarr", series_id=series_id, episode_ids=ids) for release in releases]
        for episode in aired[:2]:
            registered.extend(self.episode_releases(episode["id"])[:1])
        return registered

    def series_releases(self, series_id: int) -> list[dict]:
        seasons = sorted({episode["seasonNumber"] for episode in self.episodes.get(series_id, []) if episode["seasonNumber"] > 0})
        releases: list[dict] = []
        for number in seasons:
            releases.extend(self.season_releases(series_id, number)[:2])
        return releases

    def grab(self, guid: str) -> dict | None:
        """Send a release to the mocked download client and the activity queue."""
        meta = self.release_meta.get(guid)
        if meta is None:
            return None
        infohash = hashlib.sha1(guid.encode()).hexdigest()
        role = meta["role"]
        title = meta["title"]
        episode_ids = meta.get("episode_ids") or []
        files = None
        if role == "sonarr" and len(episode_ids) > 1:
            series = self.series.get(meta.get("series_id") or 0) or {"title": "Unknown"}
            prefix = series["title"].replace(" ", ".")
            files = []
            for episode_id in episode_ids:
                episode = self.episode(episode_id)
                if episode:
                    code = f"S{episode['seasonNumber']:02d}E{episode['episodeNumber']:02d}"
                    files.append({"name": f"{title}/{prefix}.{code}.1080p.WEB-DL.mkv", "size": meta["size"] // len(episode_ids)})
        if self.torrent(infohash) is None:
            self.add_torrent(
                infohash,
                title,
                state="downloading",
                progress=0.0,
                category=role,
                size=meta["size"],
                auto=True,
                files=files,
                front=True,
            )
        self.add_queue(
            role,
            title,
            movie_id=meta.get("movie_id"),
            series_id=meta.get("series_id"),
            episode_ids=meta.get("episode_ids"),
            download_id=infohash,
        )
        self.download_meta[infohash.upper()]["guid"] = guid
        if role == "radarr":
            self.add_history(role, "grabbed", title, movie_id=meta.get("movie_id"), download_id=infohash)
        else:
            for episode_id in meta.get("episode_ids") or []:
                self.add_history(role, "grabbed", title, series_id=meta.get("series_id"), episode_id=episode_id, download_id=infohash)
        self.log(role, "info", "DownloadService", f"Report sent to qBittorrent from indexer 1337x (Prowlarr). {title}")
        self.sync_queues()
        return meta

    def _queued_movie(self, movie_id: int) -> bool:
        return any(item.get("movieId") == movie_id for item in self.queue)

    def _queued_episode(self, episode_id: int) -> bool:
        return any(
            episode_id in (self.download_meta.get(item["downloadId"], {}).get("episode_ids") or [item.get("episodeId")])
            for item in self.series_queue
        )

    def search_movies(self, movie_ids: list[int]) -> int:
        """Grab the best acceptable release for each missing movie."""
        grabbed = 0
        for movie_id in movie_ids:
            movie = self.movies.get(int(movie_id))
            if movie is None or movie.get("hasFile") or self._queued_movie(movie["id"]):
                self.log("radarr", "info", "ReleaseSearchService", f"Searching indexers for [{movie['title'] if movie else movie_id}]. 0 reports downloaded.")
                continue
            releases = [release for release in self.movie_releases(movie["id"]) if not release["rejected"]]
            if releases and self.grab(releases[0]["guid"]):
                grabbed += 1
        return grabbed

    def search_episodes(self, episode_ids: list[int]) -> int:
        """Grab an episode release for each aired, missing, monitored episode."""
        grabbed = 0
        for episode_id in episode_ids:
            episode = self.episode(int(episode_id))
            if (
                episode is None
                or episode.get("hasFile")
                or not episode.get("monitored")
                or parse_time(episode["airDateUtc"]) > now()
                or self._queued_episode(episode["id"])
            ):
                continue
            releases = [release for release in self.episode_releases(episode["id"]) if not release["rejected"]]
            if releases and self.grab(releases[0]["guid"]):
                grabbed += 1
        if not grabbed:
            self.log("sonarr", "info", "ReleaseSearchService", "Episode search completed. 0 reports downloaded.")
        return grabbed

    # Imports ----------------------------------------------------------------

    def import_movie(self, movie_id: int, path: str, download_id: str | None, size: int | None = None) -> bool:
        movie = self.movies.get(movie_id)
        if movie is None:
            return False
        name = path.rsplit("/", 1)[-1]
        extension = name.rsplit(".", 1)[-1] if "." in name else "mkv"
        file = media_file(self.next_id("file"), f"{movie['folderName']} {quality_from_title(name)['quality']['name']}.{extension}", movie["path"], size=size or 8_000_000_000, added=now())
        attach_movie_file(movie, file)
        self.add_history("radarr", "downloadFolderImported", name.rsplit(".", 1)[0], movie_id=movie_id, download_id=download_id, data={"droppedPath": path, "importedPath": file["path"]})
        if download_id:
            self.queue = [item for item in self.queue if item["downloadId"] != download_id.upper()]
        self.log("radarr", "info", "ImportApprovedMovie", f"Imported {name} into {movie['title']}")
        return True

    def import_episodes(self, series_id: int, episode_ids: list[int], path: str, download_id: str | None) -> bool:
        episodes = [self.episode(int(item)) for item in episode_ids]
        episodes = [episode for episode in episodes if episode and episode["seriesId"] == series_id]
        if not episodes or series_id not in self.series:
            return False
        name = path.rsplit("/", 1)[-1]
        self._attach_episode_file(series_id, episodes, name, now(), download_id.upper() if download_id else None)
        for episode in episodes:
            self.add_history("sonarr", "downloadFolderImported", name.rsplit(".", 1)[0], series_id=series_id, episode_id=episode["id"], download_id=download_id, data={"droppedPath": path})
        if download_id:
            imported = {episode["id"] for episode in episodes}
            remaining = []
            for item in self.series_queue:
                if item["downloadId"] != download_id.upper():
                    remaining.append(item)
                    continue
                wanted = set(self.download_meta.get(item["downloadId"], {}).get("episode_ids") or [item.get("episodeId")])
                if not wanted <= imported | {episode["id"] for episode in self.episodes.get(series_id, []) if episode.get("hasFile")}:
                    remaining.append(item)
            self.series_queue = remaining
        self.refresh_series(series_id)
        self.log("sonarr", "info", "ImportApprovedEpisodes", f"Imported {name} into {self.series[series_id]['title']}")
        return True

    def auto_import(self, torrent: dict) -> None:
        """Import a finished grab the way Completed Download Handling does."""
        meta = self.download_meta.get(torrent["hash"].upper())
        if meta is None:
            return
        video = [item for item in self.files.get(torrent["hash"], []) if item["name"].endswith(".mkv") and "sample" not in item["name"].lower()]
        if meta["role"] == "radarr" and meta.get("movie_id") and video:
            self.import_movie(meta["movie_id"], f"{torrent['save_path']}/{video[0]['name']}", torrent["hash"], video[0]["size"])
            return
        if meta["role"] != "sonarr" or not meta.get("series_id"):
            return
        wanted = meta.get("episode_ids") or []
        for file in video:
            match = re.search(r"S(\d{2})E(\d{2})", file["name"], re.I)
            matched = [
                episode_id
                for episode_id in wanted
                if match
                and (episode := self.episode(episode_id))
                and episode["seasonNumber"] == int(match.group(1))
                and episode["episodeNumber"] == int(match.group(2))
            ]
            self.import_episodes(meta["series_id"], matched or wanted, f"{torrent['save_path']}/{file['name']}", torrent["hash"])

    def import_candidates(self, role: str, *, download_id: str | None, folder: str | None, base: str, handler: "Handler") -> list[dict]:
        """List importable files the way `/manualimport` does."""
        if download_id:
            torrents = [item for item in self.torrents if item["hash"].upper() == download_id]
        elif folder:
            wanted = folder.rstrip("/")
            torrents = [
                item
                for item in self.torrents
                if item["save_path"].rstrip("/") == wanted or item["content_path"].rstrip("/") == wanted
            ]
        else:
            torrents = []
        candidates = []
        for torrent in torrents:
            if torrent["progress"] < 1 and not download_id:
                continue
            meta = self.download_meta.get(torrent["hash"].upper(), {})
            for file in self.files.get(torrent["hash"], []):
                if not file["name"].endswith(".mkv"):
                    continue
                name = file["name"].rsplit("/", 1)[-1]
                rejections = []
                if "sample" in file["name"].lower():
                    rejections.append({"reason": "Sample", "type": "permanent"})
                entry = {
                    "id": len(candidates) + 1,
                    "path": f"{torrent['save_path']}/{file['name']}",
                    "relativePath": file["name"],
                    "folderName": file["name"].split("/")[0] if "/" in file["name"] else torrent["name"],
                    "name": name.rsplit(".", 1)[0],
                    "size": file["size"],
                    "quality": quality_from_title(name),
                    "languages": [ENGLISH],
                    "releaseGroup": "LAB",
                    "indexerFlags": 0,
                    "downloadId": torrent["hash"].upper(),
                    "customFormats": [],
                    "customFormatScore": 0,
                    "rejections": rejections,
                }
                if role == "radarr":
                    movie = self.movies.get(meta.get("movie_id") or 0) or next(
                        (item for item in self.movies.values() if normalize(item["title"]) and normalize(torrent["name"]).startswith(normalize(item["title"]))),
                        None,
                    )
                    if movie is None:
                        entry["rejections"].append({"reason": "Unknown Movie", "type": "permanent"})
                    else:
                        entry["movie"] = handler._with_base(movie, base)
                        if movie.get("hasFile") and movie["movieFile"]["quality"]["quality"]["resolution"] >= entry["quality"]["quality"]["resolution"]:
                            entry["rejections"].append({"reason": "Not an upgrade for existing movie file", "type": "permanent"})
                else:
                    series = self.series.get(meta.get("series_id") or 0) or next(
                        (item for item in self.series.values() if normalize(torrent["name"]).startswith(normalize(item["title"]))),
                        None,
                    )
                    match = re.search(r"S(\d{2})E(\d{2})", name, re.I)
                    episodes = []
                    if series and match:
                        episodes = [
                            episode
                            for episode in self.episodes.get(series["id"], [])
                            if episode["seasonNumber"] == int(match.group(1)) and episode["episodeNumber"] == int(match.group(2))
                        ]
                    elif series and meta.get("episode_ids"):
                        episodes = [self.episode(item) for item in meta["episode_ids"][:1]]
                    if series is None:
                        entry["rejections"].append({"reason": "Unknown Series", "type": "permanent"})
                    else:
                        entry["series"] = handler._with_base(series, base)
                        entry["seasonNumber"] = episodes[0]["seasonNumber"] if episodes else None
                        entry["episodes"] = [copy.deepcopy(episode) for episode in episodes if episode]
                        entry["releaseType"] = "singleEpisode"
                        if not episodes:
                            entry["rejections"].append({"reason": "Unable to determine episode from file name", "type": "permanent"})
                        elif all(episode.get("hasFile") for episode in episodes):
                            entry["rejections"].append({"reason": "Not an upgrade for existing episode file(s)", "type": "permanent"})
                candidates.append(entry)
        return candidates

    # Queue removal ----------------------------------------------------------

    def remove_queue_item(self, role: str, item_id: int, *, remove_from_client: bool, blocklist: bool, skip_redownload: bool) -> bool:
        queue = self.queue if role == "radarr" else self.series_queue
        item = next((entry for entry in queue if entry["id"] == item_id), None)
        if item is None:
            return False
        if role == "radarr":
            self.queue = [entry for entry in self.queue if entry["id"] != item_id]
        else:
            self.series_queue = [entry for entry in self.series_queue if entry["id"] != item_id]
        meta = self.download_meta.get(item["downloadId"], {})
        if remove_from_client:
            self.remove_torrents({item["downloadId"]})
        if blocklist:
            self.blocklist.append(
                {
                    "id": len(self.blocklist) + 1,
                    "sourceTitle": item["title"],
                    "movieId": item.get("movieId"),
                    "seriesId": item.get("seriesId"),
                    "date": iso(now()),
                }
            )
            if role == "radarr":
                self.add_history(role, "downloadFailed", item["title"], movie_id=item.get("movieId"), download_id=item["downloadId"], data={"message": "Manually marked as failed"})
            else:
                for episode_id in meta.get("episode_ids") or [item.get("episodeId")]:
                    self.add_history(role, "downloadFailed", item["title"], series_id=item.get("seriesId"), episode_id=episode_id, download_id=item["downloadId"], data={"message": "Manually marked as failed"})
            if not skip_redownload:
                if role == "radarr" and item.get("movieId"):
                    self.search_movies([item["movieId"]])
                elif role == "sonarr":
                    self.search_episodes(meta.get("episode_ids") or [item.get("episodeId")])
        return True

    # Simulation -------------------------------------------------------------

    def tick(self) -> None:
        """Advance downloads, finish rechecks, and refresh the queues."""
        moment = time.monotonic()
        elapsed = moment - self.last_tick
        self.last_tick = moment
        for torrent in list(self.torrents):
            sim = self.sim.setdefault(torrent["hash"], {"auto": False, "speed": 4_000_000})
            until = sim.get("recheck_until")
            if until is not None:
                if moment >= until:
                    sim.pop("recheck_until")
                    self.apply_state(torrent, sim.pop("after_recheck", torrent["state"]))
                continue
            if torrent["state"] in ("uploading", "stalledUP", "forcedUP"):
                torrent["seeding_time"] += int(elapsed)
                torrent["time_active"] += int(elapsed)
                torrent["uploaded"] += int(torrent["upspeed"] * elapsed)
                torrent["ratio"] = round(torrent["uploaded"] / max(torrent["downloaded"], 1), 3)
                continue
            if torrent["state"] not in ("downloading", "forcedDL"):
                continue
            torrent["time_active"] += int(elapsed)
            total = torrent["total_size"]
            progress = torrent["progress"] + sim["speed"] * elapsed / max(total, 1)
            if sim["auto"]:
                if progress >= 1:
                    torrent["progress"] = 1
                    torrent["completion_on"] = int(time.time())
                    torrent["downloaded"] = total
                    torrent["amount_left"] = 0
                    for file in self.files.get(torrent["hash"], []):
                        file["progress"] = 1
                        file["is_seed"] = True
                    self.apply_state(torrent, "uploading")
                    self.auto_import(torrent)
                    continue
            elif progress >= FIXTURE_STALL_AT:
                progress = FIXTURE_STALL_AT
                torrent["progress"] = progress
                self.apply_state(torrent, "stalledDL")
            torrent["progress"] = round(progress, 4)
            torrent["downloaded"] = int(total * torrent["progress"])
            torrent["amount_left"] = total - torrent["downloaded"]
            for file in self.files.get(torrent["hash"], []):
                file["progress"] = torrent["progress"] if file["priority"] else 0
            if torrent["state"] == "downloading":
                torrent["eta"] = int(torrent["amount_left"] / max(torrent["dlspeed"], 1))
        self.sync_queues()

    def sync_queues(self) -> None:
        """Mirror torrent progress into the queues; drop items the client lost."""
        for role in ("radarr", "sonarr"):
            queue = self.queue if role == "radarr" else self.series_queue
            kept = []
            for item in queue:
                torrent = self.torrent(item["downloadId"])
                if torrent is None:
                    continue
                total = torrent["total_size"]
                item["size"] = total
                item["sizeleft"] = int(total * (1 - torrent["progress"]))
                state = torrent["state"]
                if torrent["progress"] >= 1:
                    item["status"] = "completed"
                    if item["trackedDownloadState"] == "downloading":
                        item["trackedDownloadState"] = "importPending"
                    item.pop("timeleft", None)
                    item.pop("estimatedCompletionTime", None)
                elif state in STOPPED_STATES:
                    item["status"] = "paused"
                elif state == "stalledDL":
                    item["status"] = "warning"
                    item["trackedDownloadStatus"] = "warning"
                    item["statusMessages"] = [{"title": item["title"], "messages": [STALLED_MESSAGE]}]
                elif state == "error":
                    item["status"] = "failed"
                    item["trackedDownloadStatus"] = "error"
                elif state.startswith("checking") or state.startswith("queued"):
                    item["status"] = "queued"
                else:
                    item["status"] = "downloading"
                    if any(STALLED_MESSAGE in entry["messages"] for entry in item["statusMessages"]):
                        item["trackedDownloadStatus"] = "ok"
                        item["statusMessages"] = []
                if torrent["progress"] < 1 and torrent["dlspeed"]:
                    seconds = int(item["sizeleft"] / torrent["dlspeed"])
                    days, rest = divmod(seconds, 86_400)
                    clock = f"{rest // 3600:02d}:{rest % 3600 // 60:02d}:{rest % 60:02d}"
                    item["timeleft"] = f"{days}.{clock}" if days else clock
                    item["estimatedCompletionTime"] = iso(now() + timedelta(seconds=seconds))
                elif torrent["progress"] < 1:
                    item.pop("timeleft", None)
                    item.pop("estimatedCompletionTime", None)
                kept.append(item)
            if role == "radarr":
                self.queue = kept
            else:
                self.series_queue = kept

    # Commands ---------------------------------------------------------------

    def run_command(self, role: str, incoming: dict) -> dict:
        name = str(incoming.get("name") or "")
        message = "Completed"
        if role == "radarr":
            if name == "MoviesSearch":
                grabbed = self.search_movies([int(item) for item in incoming.get("movieIds") or []])
                message = f"{grabbed} release(s) grabbed"
            elif name in ("RefreshMovie", "RescanMovie"):
                ids = incoming.get("movieIds") or ([incoming["movieId"]] if incoming.get("movieId") else list(self.movies))
                for movie_id in ids:
                    movie = self.movies.get(int(movie_id))
                    if movie:
                        self.log(role, "info", "RefreshMovieService", f"Updating info for {movie['title']}" if name == "RefreshMovie" else f"Scanning disk for {movie['title']}")
            elif name == "ManualImport":
                imported = 0
                for file in incoming.get("files") or []:
                    if file.get("movieId") and self.import_movie(int(file["movieId"]), str(file.get("path") or "import.mkv"), file.get("downloadId")):
                        imported += 1
                message = f"{imported} file(s) imported"
        else:
            if name == "EpisodeSearch":
                grabbed = self.search_episodes([int(item) for item in incoming.get("episodeIds") or []])
                message = f"{grabbed} release(s) grabbed"
            elif name == "SeasonSearch":
                series_id = int(incoming.get("seriesId") or 0)
                season_number = int(incoming.get("seasonNumber") or 0)
                ids = [episode["id"] for episode in self.episodes.get(series_id, []) if episode["seasonNumber"] == season_number]
                message = f"{self.search_episodes(ids)} release(s) grabbed"
            elif name == "SeriesSearch":
                series_id = int(incoming.get("seriesId") or 0)
                ids = [episode["id"] for episode in self.episodes.get(series_id, []) if episode["seasonNumber"] > 0]
                message = f"{self.search_episodes(ids)} release(s) grabbed"
            elif name in ("RefreshSeries", "RescanSeries"):
                series = self.series.get(int(incoming.get("seriesId") or 0))
                if series:
                    self.refresh_series(series["id"])
                    self.log(role, "info", "RefreshSeriesService", f"Updating info for {series['title']}" if name == "RefreshSeries" else f"Scanning disk for {series['title']}")
            elif name == "ManualImport":
                imported = 0
                for file in incoming.get("files") or []:
                    if file.get("seriesId") and self.import_episodes(int(file["seriesId"]), file.get("episodeIds") or [], str(file.get("path") or "import.mkv"), file.get("downloadId")):
                        imported += 1
                message = f"{imported} file(s) imported"
        if name not in ("RefreshMovie", "RescanMovie", "RefreshSeries", "RescanSeries"):
            self.log(role, "info", "CommandExecutor", f"{name}: {message}")
        stamp = iso(now())
        command = {
            "id": self.next_id("command"),
            "name": name,
            "commandName": re.sub(r"(?<!^)(?=[A-Z])", " ", name),
            "message": message,
            "body": incoming,
            "priority": "normal",
            "status": "completed",
            "result": "successful",
            "queued": stamp,
            "started": stamp,
            "ended": stamp,
            "duration": "00:00:00.1000000",
            "trigger": "manual",
            "stateChangeTime": stamp,
            "sendUpdatesToClient": True,
            "updateScheduledTask": True,
        }
        self.commands[command["id"]] = command
        return command


LAB = Lab()


class Handler(BaseHTTPRequestHandler):
    """HTTP handler that dispatches by listening port."""

    protocol_version = "HTTP/1.1"

    def log_message(self, fmt: str, *args) -> None:
        print(f"[MediaLab] {self.address_string()} {fmt % args}")

    @property
    def role(self) -> str:
        port = self.server.server_address[1]
        return {7878: "radarr", 8989: "sonarr", 9696: "prowlarr", 8080: "qbit"}.get(
            port, "unknown"
        )

    def do_OPTIONS(self) -> None:
        self._send(204, b"", "text/plain")

    def do_GET(self) -> None:
        self._route("GET")

    def do_POST(self) -> None:
        self._route("POST")

    def do_PUT(self) -> None:
        self._route("PUT")

    def do_DELETE(self) -> None:
        self._route("DELETE")

    def _route(self, method: str) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"
        query = parse_qs(parsed.query)
        body = self._body()
        if path.startswith("/MediaCover/"):
            self._cover(path)
            return
        if self.role == "qbit":
            self._qbit(method, path, query, body)
            return
        if path == "/ping":
            self._json({"status": "OK"})
            return
        if not self._authorized():
            self._json({"message": "Unauthorized"}, 401)
            return
        if self.role == "prowlarr":
            self._prowlarr(method, path, query, body)
            return
        with LOCK:
            LAB.tick()
            if self.role == "radarr":
                self._radarr(method, path, query, body)
            else:
                self._sonarr(method, path, query, body)

    def _authorized(self) -> bool:
        expected = {
            "radarr": RADARR_KEY,
            "sonarr": SONARR_KEY,
            "prowlarr": PROWLARR_KEY,
        }[self.role]
        supplied = self.headers.get("X-Api-Key") or (parse_qs(urlparse(self.path).query).get("apikey") or [None])[0]
        return supplied == expected

    def _base(self) -> str:
        host = self.headers.get("Host", "127.0.0.1")
        return f"http://{host}"

    def _body(self) -> bytes:
        length = int(self.headers.get("Content-Length", "0") or 0)
        return self.rfile.read(length) if length else b""

    def _json_body(self, body: bytes) -> dict:
        if not body:
            return {}
        parsed = json.loads(body.decode())
        return parsed if isinstance(parsed, dict) else {}

    def _form(self, body: bytes) -> tuple[dict[str, list[str]], list[tuple[str, bytes]]]:
        """Parse a urlencoded or multipart form into fields and uploads."""
        content_type = self.headers.get("Content-Type", "")
        if "multipart/form-data" not in content_type:
            return parse_qs(body.decode(errors="replace"), keep_blank_values=True), []
        match = re.search(r"boundary=([^;]+)", content_type)
        boundary = match.group(1).strip().strip('"') if match else ""
        fields: dict[str, list[str]] = {}
        uploads: list[tuple[str, bytes]] = []
        for chunk in body.split(f"--{boundary}".encode()):
            if b"\r\n\r\n" not in chunk:
                continue
            head, value = chunk.split(b"\r\n\r\n", 1)
            value = value.rsplit(b"\r\n", 1)[0]
            name = re.search(br'name="([^"]+)"', head)
            filename = re.search(br'filename="([^"]*)"', head)
            if not name:
                continue
            if filename:
                uploads.append((filename.group(1).decode(errors="replace"), value))
            else:
                fields.setdefault(name.group(1).decode(), []).append(value.decode(errors="replace"))
        return fields, uploads

    def _send(self, status: int, payload: bytes, content_type: str, extra: dict | None = None) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header(
            "Access-Control-Allow-Headers",
            "X-Api-Key, Authorization, Content-Type",
        )
        self.send_header(
            "Access-Control-Allow-Methods",
            "GET, POST, PUT, DELETE, OPTIONS",
        )
        for key, value in (extra or {}).items():
            self.send_header(key, value)
        self.end_headers()
        self.wfile.write(payload)

    def _json(self, payload: object, status: int = 200, extra: dict | None = None) -> None:
        encoded = json.dumps(payload).encode()
        self._send(status, encoded, "application/json", extra)

    def _text(self, payload: str, status: int = 200, extra: dict | None = None) -> None:
        self._send(status, payload.encode(), "text/plain", extra)

    def _not_found(self) -> None:
        self._json({"message": "NotFound", "description": "Resource not found"}, 404)

    def _cover(self, path: str) -> None:
        parts = [part for part in path.split("/") if part]
        seed = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 1
        wide = "fanart" in path
        self._send(200, cover_bytes(seed, wide), "image/png")

    def _history_names(self, query: dict) -> set[str] | None:
        """Map Radarr/Sonarr numeric history filters onto event names."""
        raw = query.get("eventType") or []
        if not raw:
            return None
        tokens: list[str] = []
        for value in raw:
            tokens.extend(part.strip() for part in value.split(",") if part.strip())
        radarr = {
            "1": {"grabbed"},
            "3": {"downloadFolderImported", "movieFolderImported"},
            "4": {"downloadFailed"},
            "6": {"movieFileDeleted"},
            "8": {"movieFileRenamed"},
            "9": {"downloadIgnored"},
        }
        sonarr = {
            "1": {"grabbed"},
            "2": {"seriesFolderImported"},
            "3": {"downloadFolderImported"},
            "4": {"downloadFailed"},
            "5": {"episodeFileDeleted"},
            "6": {"episodeFileRenamed"},
            "7": {"downloadIgnored"},
        }
        table = radarr if self.role == "radarr" else sonarr
        names: set[str] = set()
        for token in tokens:
            if token.isdigit():
                names |= table.get(token, set())
            else:
                names.add(token)
        return names

    def _page(self, records: list, query: dict, *, sort_by_date: str | None = None) -> dict:
        page = int((query.get("page") or ["1"])[0])
        page_size = int((query.get("pageSize") or ["50"])[0])
        filtered = records
        if sort_by_date:
            filtered = sorted(filtered, key=lambda item: item.get(sort_by_date) or "", reverse=True)
        start = (page - 1) * page_size
        return {
            "page": page,
            "pageSize": page_size,
            "sortKey": (query.get("sortKey") or ["date"])[0],
            "sortDirection": (query.get("sortDirection") or ["descending"])[0],
            "totalRecords": len(filtered),
            "records": filtered[start : start + page_size],
        }

    def _with_base(self, record: dict, base: str | None = None) -> dict:
        copied = copy.deepcopy(record)
        seed = copied.get("tmdbId") or copied.get("tvdbId") or copied.get("id") or 1
        copied["images"] = images_for(int(seed), base or self._base())
        return copied

    def _system(self, app_name: str, version: str) -> dict:
        return {
            "appName": app_name,
            "instanceName": f"Arrmate Lab {app_name}",
            "version": version,
            "buildTime": iso(NOW - timedelta(days=40)),
            "isDebug": False,
            "isProduction": True,
            "isDocker": True,
            "osName": "ubuntu",
            "authentication": "forms",
            "startTime": iso(NOW),
            "urlBase": "",
            "branch": "main",
        }

    def _common(self, method: str, path: str, query: dict, body: bytes, app_name: str, version: str) -> bool:
        role = self.role
        movies = role == "radarr"
        if method == "GET" and path == "/api/v3/system/status":
            self._json(self._system(app_name, version))
            return True
        if method == "GET" and path == "/api/v3/diskspace":
            self._json(
                [
                    {"path": "/movies" if movies else "/tv", "label": "Media", "freeSpace": 800_000_000_000, "totalSpace": 2_000_000_000_000},
                    {"path": "/movies-4k" if movies else "/tv-anime", "label": "Archive", "freeSpace": 120_000_000_000, "totalSpace": 4_000_000_000_000},
                    {"path": "/downloads", "label": "Downloads", "freeSpace": 300_000_000_000, "totalSpace": 1_000_000_000_000},
                ]
            )
            return True
        if method == "GET" and path == "/api/v3/qualityprofile":
            self._json([{"id": 1, "name": "HD-1080p", "cutoff": 7}, {"id": 2, "name": "Ultra-HD", "cutoff": 31}])
            return True
        if method == "GET" and path == "/api/v3/rootfolder":
            folders = ["/movies", "/movies-4k"] if movies else ["/tv", "/tv-anime"]
            self._json(
                [
                    {"id": index + 1, "path": folder, "accessible": True, "freeSpace": 800_000_000_000 if index == 0 else 120_000_000_000, "unmappedFolders": []}
                    for index, folder in enumerate(folders)
                ]
            )
            return True
        if method == "GET" and path == "/api/v3/health":
            self._json(
                [
                    {
                        "source": "DownloadClientCheck",
                        "type": "warning",
                        "message": "qBittorrent is the Arrmate lab mock. Downloads are simulated.",
                        "wikiUrl": "https://wiki.servarr.com/",
                    },
                    {
                        "source": "IndexerStatusCheck",
                        "type": "warning",
                        "message": "Indexers unavailable due to failures: TorrentDay (Prowlarr)",
                        "wikiUrl": "https://wiki.servarr.com/",
                    },
                ]
            )
            return True
        if method == "GET" and path == "/api/v3/log":
            records = LAB.logs[role]
            level = (query.get("level") or [None])[0]
            if level:
                records = [item for item in records if item["level"] == level]
            self._json(self._page(records, query))
            return True
        if method == "GET" and path == "/api/v3/tag":
            self._json([{"id": 1, "label": "lab"}, {"id": 2, "label": "4k"}])
            return True
        if method == "GET" and path == "/api/v3/downloadclient":
            self._json(
                [
                    {
                        "id": 1,
                        "name": "qBittorrent",
                        "implementation": "QBittorrent",
                        "enable": True,
                        "protocol": "torrent",
                        "fields": [
                            {"name": "host", "value": "127.0.0.1"},
                            {"name": "port", "value": 8080},
                            {"name": "movieCategory" if movies else "tvCategory", "value": role},
                        ],
                    }
                ]
            )
            return True
        if method == "GET" and path == "/api/v3/notification/schema":
            self._json(
                [
                    {
                        "name": "ntfy",
                        "implementation": "Ntfy",
                        "implementationName": "ntfy.sh",
                        "configContract": "NtfySettings",
                        "fields": [
                            {"name": "serverUrl", "value": "https://ntfy.sh"},
                            {"name": "topics", "value": []},
                            {"name": "priority", "value": 3},
                        ],
                        "tags": [],
                    }
                ]
            )
            return True
        if path == "/api/v3/notification" and method == "GET":
            self._json(LAB.notifications[role])
            return True
        if path == "/api/v3/notification" and method == "POST":
            incoming = self._json_body(body)
            LAB.next_ids["notification"][role] += 1
            incoming["id"] = LAB.next_ids["notification"][role]
            LAB.notifications[role].append(incoming)
            self._json(incoming, 201)
            return True
        if re.fullmatch(r"/api/v3/notification/\d+", path):
            item_id = int(path.rsplit("/", 1)[-1])
            index = next((i for i, item in enumerate(LAB.notifications[role]) if item["id"] == item_id), None)
            if index is None:
                self._not_found()
                return True
            if method == "GET":
                self._json(LAB.notifications[role][index])
            elif method == "PUT":
                incoming = self._json_body(body)
                incoming["id"] = item_id
                LAB.notifications[role][index] = incoming
                self._json(incoming, 202)
            elif method == "DELETE":
                LAB.notifications[role].pop(index)
                self._json({})
            else:
                return False
            return True
        if method == "POST" and path == "/api/v3/command":
            self._json(LAB.run_command(role, self._json_body(body)), 201)
            return True
        if method == "GET" and path == "/api/v3/command":
            self._json(list(LAB.commands.values())[-20:])
            return True
        if method == "GET" and re.fullmatch(r"/api/v3/command/\d+", path):
            command = LAB.commands.get(int(path.rsplit("/", 1)[-1]))
            if command is None:
                self._not_found()
            else:
                self._json(command)
            return True
        if method == "GET" and path == "/api/v3/blocklist":
            records = [item for item in LAB.blocklist if (item.get("movieId") is not None) == movies]
            self._json(self._page(records, query, sort_by_date="date"))
            return True
        if method == "DELETE" and re.fullmatch(r"/api/v3/queue/\d+", path):
            removed = LAB.remove_queue_item(
                role,
                int(path.rsplit("/", 1)[-1]),
                remove_from_client=flag(query, "removeFromClient", True),
                blocklist=flag(query, "blocklist", False),
                skip_redownload=flag(query, "skipRedownload", False),
            )
            if removed:
                self._json({})
            else:
                self._not_found()
            return True
        if method == "GET" and path == "/api/v3/manualimport":
            download_id = (query.get("downloadId") or [None])[0]
            folder = (query.get("folder") or [None])[0]
            self._json(LAB.import_candidates(role, download_id=download_id, folder=folder, base=self._base(), handler=self))
            return True
        return False

    def _calendar_range(self, query: dict) -> tuple[datetime, datetime]:
        start = parse_time((query.get("start") or [None])[0])
        end = parse_time((query.get("end") or [None])[0])
        today = now().replace(hour=0, minute=0, second=0, microsecond=0)
        return start or today, end or today + timedelta(days=2)

    def _radarr(self, method: str, path: str, query: dict, body: bytes) -> None:
        if self._common(method, path, query, body, "Radarr", "5.18.4.9674"):
            return
        if method == "GET" and path == "/api/v3/movie":
            tmdb = (query.get("tmdbId") or [None])[0]
            movies = [movie for movie in LAB.movies.values() if tmdb is None or str(movie["tmdbId"]) == tmdb]
            self._json([self._with_base(movie) for movie in movies])
            return
        if method == "GET" and path == "/api/v3/movie/lookup":
            term = (query.get("term") or [""])[0].strip().lower()
            pool = list(LAB.movies.values()) + [
                movie for movie in LAB.lookup_movies if all(item["tmdbId"] != movie["tmdbId"] for item in LAB.movies.values())
            ]
            identifier = re.fullmatch(r"(tmdb|imdb):\s*(\S+)", term)
            if identifier:
                kind, value = identifier.groups()
                matched = [movie for movie in pool if (str(movie["tmdbId"]) == value if kind == "tmdb" else movie["imdbId"] == value)]
            else:
                matched = [
                    movie
                    for movie in pool
                    if term in movie["title"].lower() or term in (movie.get("overview") or "").lower()
                ]
            self._json([self._with_base(movie) for movie in matched])
            return
        if re.fullmatch(r"/api/v3/movie/\d+", path):
            movie_id = int(path.rsplit("/", 1)[-1])
            movie = LAB.movies.get(movie_id)
            if movie is None:
                self._not_found()
                return
            if method == "GET":
                self._json(self._with_base(movie))
                return
            if method == "PUT":
                incoming = self._json_body(body)
                for key in ("monitored", "qualityProfileId", "minimumAvailability", "tags", "rootFolderPath", "path"):
                    if key in incoming:
                        movie[key] = incoming[key]
                set_availability(movie)
                self._json(self._with_base(movie), 202)
                return
            if method == "DELETE":
                delete_files = flag(query, "deleteFiles", False)
                if flag(query, "addImportExclusion", False):
                    LAB.exclusions["radarr"].add(movie["tmdbId"])
                LAB.movies.pop(movie_id)
                LAB.history = [event for event in LAB.history if event.get("movieId") != movie_id]
                LAB.log("radarr", "info", "MovieService", f"Deleted movie {movie['title']}" + (" and its files" if delete_files else ""))
                self._json({})
                return
        if method == "POST" and path == "/api/v3/movie":
            incoming = self._json_body(body)
            tmdb_id = int(incoming.get("tmdbId") or 0)
            if any(movie["tmdbId"] == tmdb_id for movie in LAB.movies.values()):
                self._json([{"propertyName": "TmdbId", "errorMessage": "This movie has already been added"}], 400)
                return
            movie_id = LAB.next_id("movie")
            template = next((movie for movie in LAB.lookup_movies if movie["tmdbId"] == tmdb_id), None)
            if template:
                created = copy.deepcopy(template)
            else:
                created = movie_record(movie_id, tmdb_id or movie_id, incoming.get("title") or "Untitled", int(incoming.get("year") or NOW.year), incoming.get("overview") or "Added from the Arrmate lab.", in_library=True)
            root = incoming.get("rootFolderPath") or "/movies"
            created.update(
                {
                    "id": movie_id,
                    "monitored": bool(incoming.get("monitored", True)),
                    "qualityProfileId": incoming.get("qualityProfileId") or 1,
                    "minimumAvailability": incoming.get("minimumAvailability") or "released",
                    "rootFolderPath": root,
                    "path": incoming.get("path") or f"{root}/{created['folderName']}",
                    "tags": incoming.get("tags") or [],
                    "added": iso(now()),
                }
            )
            set_availability(created)
            LAB.movies[movie_id] = created
            LAB.log("radarr", "info", "AddMovieService", f"Added movie {created['title']} ({created['year']})")
            if (incoming.get("addOptions") or {}).get("searchForMovie"):
                LAB.search_movies([movie_id])
            self._json(self._with_base(created), 201)
            return
        if method == "PUT" and path == "/api/v3/movie/editor":
            incoming = self._json_body(body)
            for movie_id in incoming.get("movieIds") or []:
                movie = LAB.movies.get(int(movie_id))
                if movie is None:
                    continue
                for key in ("monitored", "qualityProfileId", "minimumAvailability"):
                    if key in incoming:
                        movie[key] = incoming[key]
                if "tags" in incoming:
                    mode = incoming.get("applyTags") or "add"
                    current = set(movie.get("tags") or [])
                    wanted = set(incoming["tags"] or [])
                    movie["tags"] = sorted(wanted if mode == "replace" else current | wanted if mode == "add" else current - wanted)
                root = incoming.get("rootFolderPath")
                if root and root != movie.get("rootFolderPath"):
                    movie["rootFolderPath"] = root
                    movie["path"] = f"{root.rstrip('/')}/{movie['folderName']}"
                    if incoming.get("moveFiles") and movie.get("movieFile"):
                        movie["movieFile"]["path"] = f"{movie['path']}/{movie['movieFile']['relativePath']}"
                        LAB.log("radarr", "info", "MoveMovieService", f"Moved {movie['title']} to {movie['path']}")
                set_availability(movie)
            self._json([self._with_base(LAB.movies[int(item)]) for item in incoming.get("movieIds") or [] if int(item) in LAB.movies], 202)
            return
        if method == "DELETE" and path == "/api/v3/movie/editor":
            incoming = self._json_body(body)
            for movie_id in incoming.get("movieIds") or []:
                LAB.movies.pop(int(movie_id), None)
                LAB.history = [event for event in LAB.history if event.get("movieId") != int(movie_id)]
            self._json({})
            return
        if method == "GET" and path == "/api/v3/release":
            movie_id = int((query.get("movieId") or ["0"])[0])
            self._json(LAB.movie_releases(movie_id) if movie_id in LAB.movies else [])
            return
        if method == "POST" and path == "/api/v3/release":
            incoming = self._json_body(body)
            meta = LAB.grab(str(incoming.get("guid") or ""))
            if meta is None:
                self._json({"message": "Couldn't find requested release in cache, cache timeout probably expired."}, 404)
                return
            self._json(incoming)
            return
        if method == "GET" and path == "/api/v3/calendar":
            start, end = self._calendar_range(query)
            include_unmonitored = flag(query, "unmonitored", False)
            upcoming = []
            for movie in LAB.movies.values():
                if not include_unmonitored and not movie.get("monitored"):
                    continue
                dates = [parse_time(movie.get(key)) for key in ("inCinemas", "digitalRelease", "physicalRelease")]
                if any(moment and start <= moment <= end for moment in dates):
                    upcoming.append(self._with_base(movie))
            self._json(upcoming)
            return
        if method == "GET" and path == "/api/v3/queue":
            records = []
            for item in LAB.queue:
                copied = copy.deepcopy(item)
                movie = LAB.movies.get(copied.get("movieId") or 0)
                if movie:
                    copied["movie"] = self._with_base(movie)
                elif not flag(query, "includeUnknownMovieItems", False):
                    continue
                records.append(copied)
            self._json(self._page(records, query))
            return
        if method == "GET" and path == "/api/v3/history":
            names = self._history_names(query)
            movie_filter = (query.get("movieIds") or query.get("movieId") or [None])[0]
            records = []
            for event in LAB.history:
                if names is not None and event["eventType"] not in names:
                    continue
                if movie_filter and str(event.get("movieId")) != movie_filter:
                    continue
                copied = copy.deepcopy(event)
                movie = LAB.movies.get(copied.get("movieId") or 0)
                if movie and flag(query, "includeMovie", False):
                    copied["movie"] = self._with_base(movie)
                records.append(copied)
            self._json(self._page(records, query, sort_by_date="date"))
            return
        if method == "GET" and path == "/api/v3/history/movie":
            movie_id = int((query.get("movieId") or ["0"])[0])
            names = self._history_names(query)
            events = [
                event
                for event in LAB.history
                if event.get("movieId") == movie_id and (names is None or event["eventType"] in names)
            ]
            self._json(sorted(events, key=lambda item: item["date"], reverse=True))
            return
        if method == "GET" and path == "/api/v3/moviefile":
            movie_id = int((query.get("movieId") or ["0"])[0])
            movie = LAB.movies.get(movie_id)
            self._json([movie["movieFile"]] if movie and movie.get("movieFile") else [])
            return
        if re.fullmatch(r"/api/v3/moviefile/\d+", path):
            file_id = int(path.rsplit("/", 1)[-1])
            owner = next((movie for movie in LAB.movies.values() if (movie.get("movieFile") or {}).get("id") == file_id), None)
            if owner is None:
                self._not_found()
                return
            if method == "GET":
                self._json(owner["movieFile"])
                return
            if method == "DELETE":
                relative = owner["movieFile"]["relativePath"]
                attach_movie_file(owner, None)
                LAB.add_history("radarr", "movieFileDeleted", relative, movie_id=owner["id"], download_id=None, data={"reason": "Manual"})
                self._json({})
                return
        if method == "GET" and path == "/api/v3/extrafile":
            movie_id = int((query.get("movieId") or ["0"])[0])
            movie = LAB.movies.get(movie_id)
            if movie is None or not movie.get("hasFile"):
                self._json([])
                return
            self._json(
                [
                    {"id": 1, "movieId": movie_id, "movieFileId": movie["movieFile"]["id"], "relativePath": f"{movie['folderName']}.en.srt", "extension": ".srt", "type": "subtitle", "languageTags": [], "title": "English"},
                    {"id": 2, "movieId": movie_id, "movieFileId": movie["movieFile"]["id"], "relativePath": f"{movie['folderName']}.nfo", "extension": ".nfo", "type": "metadata"},
                ]
            )
            return
        self._json({"message": f"Unhandled {method} {path}"}, 404)

    def _sonarr(self, method: str, path: str, query: dict, body: bytes) -> None:
        if self._common(method, path, query, body, "Sonarr", "4.0.14.2939"):
            return
        if method == "GET" and path == "/api/v3/series":
            tvdb = (query.get("tvdbId") or [None])[0]
            self._json([self._with_base(item) for item in LAB.series.values() if tvdb is None or str(item["tvdbId"]) == tvdb])
            return
        if method == "GET" and path == "/api/v3/series/lookup":
            term = (query.get("term") or [""])[0].strip().lower()
            pool = list(LAB.series.values()) + [
                item for item in LAB.lookup_series if all(existing["tvdbId"] != item["tvdbId"] for existing in LAB.series.values())
            ]
            identifier = re.fullmatch(r"(tvdb|imdb):\s*(\S+)", term)
            if identifier:
                kind, value = identifier.groups()
                matched = [item for item in pool if (str(item["tvdbId"]) == value if kind == "tvdb" else item["imdbId"] == value)]
            else:
                matched = [
                    item
                    for item in pool
                    if term in item["title"].lower() or term in (item.get("overview") or "").lower()
                ]
            self._json([self._with_base(item) for item in matched])
            return
        if re.fullmatch(r"/api/v3/series/\d+", path):
            series_id = int(path.rsplit("/", 1)[-1])
            item = LAB.series.get(series_id)
            if item is None:
                self._not_found()
                return
            if method == "GET":
                self._json(self._with_base(item))
                return
            if method == "PUT":
                incoming = self._json_body(body)
                for key in ("monitored", "monitorNewItems", "seriesType", "seasonFolder", "qualityProfileId", "tags"):
                    if key in incoming:
                        item[key] = incoming[key]
                if isinstance(incoming.get("seasons"), list):
                    previous = {season["seasonNumber"]: season.get("monitored") for season in item["seasons"]}
                    for season in incoming["seasons"]:
                        number = season.get("seasonNumber")
                        monitored = bool(season.get("monitored"))
                        for existing in item["seasons"]:
                            if existing["seasonNumber"] == number:
                                existing["monitored"] = monitored
                        if previous.get(number) != monitored:
                            for episode in LAB.episodes.get(series_id, []):
                                if episode["seasonNumber"] == number:
                                    episode["monitored"] = monitored
                LAB.refresh_series(series_id)
                self._json(self._with_base(item), 202)
                return
            if method == "DELETE":
                if flag(query, "addImportListExclusion", False):
                    LAB.exclusions["sonarr"].add(item["tvdbId"])
                LAB.series.pop(series_id)
                LAB.episodes.pop(series_id, None)
                LAB.series_history = [event for event in LAB.series_history if event.get("seriesId") != series_id]
                LAB.log("sonarr", "info", "SeriesService", f"Deleted series {item['title']}" + (" and its files" if flag(query, "deleteFiles", False) else ""))
                self._json({})
                return
        if method == "POST" and path == "/api/v3/series":
            incoming = self._json_body(body)
            tvdb_id = int(incoming.get("tvdbId") or 0)
            if any(item["tvdbId"] == tvdb_id for item in LAB.series.values()):
                self._json([{"propertyName": "TvdbId", "errorMessage": "This series has already been added"}], 400)
                return
            series_id = LAB.next_id("series")
            template = next((item for item in LAB.lookup_series if item["tvdbId"] == tvdb_id), None)
            title = (template or incoming).get("title") or "Untitled"
            year = int((template or incoming).get("year") or NOW.year)
            created = series_record(
                series_id,
                tvdb_id or series_id,
                title,
                year,
                (template or incoming).get("overview") or "Added from the Arrmate lab.",
                in_library=True,
                seasons=[1],
                status=(template or {}).get("status", "continuing"),
                network=(template or {}).get("network", "Arrmate TV"),
            )
            root = incoming.get("rootFolderPath") or "/tv"
            created.update(
                {
                    "monitored": bool(incoming.get("monitored", True)),
                    "qualityProfileId": incoming.get("qualityProfileId") or 1,
                    "seriesType": incoming.get("seriesType") or "standard",
                    "seasonFolder": incoming.get("seasonFolder", True),
                    "monitorNewItems": incoming.get("monitorNewItems") or "all",
                    "rootFolderPath": root,
                    "path": incoming.get("path") or f"{root}/{created['folder']}",
                    "tags": incoming.get("tags") or [],
                    "added": iso(now()),
                }
            )
            LAB.series[series_id] = created
            titles = SHOGUN_S1 if tvdb_id == 417742 else ["Pilot"]
            first = datetime(year, 2, 27, 2, 0, tzinfo=timezone.utc) if template else now() + timedelta(days=2)
            options = incoming.get("addOptions") or {}
            monitor = options.get("monitor") or "all"
            episodes = []
            for index, episode_title in enumerate(titles):
                airs = first + timedelta(weeks=index)
                monitored = {
                    "none": False,
                    "future": airs > now(),
                    "pilot": index == 0,
                    "existing": False,
                }.get(monitor, True) and created["monitored"]
                episode_id = LAB.next_id("episode")
                episodes.append(episode_record(episode_id, series_id, 1, index + 1, episode_title, airs=airs, monitored=monitored))
            LAB.episodes[series_id] = episodes
            for season in created["seasons"]:
                season["monitored"] = any(episode["monitored"] for episode in episodes if episode["seasonNumber"] == season["seasonNumber"])
            LAB.refresh_series(series_id)
            LAB.log("sonarr", "info", "AddSeriesService", f"Added series {title} ({year})")
            if options.get("searchForMissingEpisodes"):
                LAB.search_episodes([episode["id"] for episode in episodes])
            self._json(self._with_base(created), 201)
            return
        if method == "PUT" and path == "/api/v3/series/editor":
            incoming = self._json_body(body)
            for series_id in incoming.get("seriesIds") or []:
                item = LAB.series.get(int(series_id))
                if item is None:
                    continue
                for key in ("monitored", "monitorNewItems", "qualityProfileId", "seriesType", "seasonFolder"):
                    if key in incoming:
                        item[key] = incoming[key]
                if "tags" in incoming:
                    mode = incoming.get("applyTags") or "add"
                    current = set(item.get("tags") or [])
                    wanted = set(incoming["tags"] or [])
                    item["tags"] = sorted(wanted if mode == "replace" else current | wanted if mode == "add" else current - wanted)
                root = incoming.get("rootFolderPath")
                if root and root != item.get("rootFolderPath"):
                    item["rootFolderPath"] = root
                    item["path"] = f"{root.rstrip('/')}/{item['folder']}"
                    if incoming.get("moveFiles"):
                        for episode in LAB.episodes.get(item["id"], []):
                            file = episode.get("episodeFile")
                            if file:
                                file["path"] = f"{item['path']}/Season {episode['seasonNumber']:02d}/{file['relativePath']}"
                        LAB.log("sonarr", "info", "MoveSeriesService", f"Moved {item['title']} to {item['path']}")
                LAB.refresh_series(item["id"])
            self._json([self._with_base(LAB.series[int(item)]) for item in incoming.get("seriesIds") or [] if int(item) in LAB.series], 202)
            return
        if method == "GET" and path == "/api/v3/episode":
            series_id = int((query.get("seriesId") or ["0"])[0])
            season_filter = (query.get("seasonNumber") or [None])[0]
            ids = {int(item) for value in query.get("episodeIds") or [] for item in value.split(",") if item}
            episodes = LAB.episodes.get(series_id, []) if series_id else [episode for items in LAB.episodes.values() for episode in items]
            self._json(
                [
                    episode
                    for episode in episodes
                    if (season_filter is None or str(episode["seasonNumber"]) == season_filter) and (not ids or episode["id"] in ids)
                ]
            )
            return
        if method == "GET" and re.fullmatch(r"/api/v3/episode/\d+", path):
            episode = LAB.episode(int(path.rsplit("/", 1)[-1]))
            if episode is None:
                self._not_found()
                return
            copied = copy.deepcopy(episode)
            series = LAB.series.get(episode["seriesId"])
            if series:
                copied["series"] = self._with_base(series)
            self._json(copied)
            return
        if method == "PUT" and path == "/api/v3/episode/monitor":
            incoming = self._json_body(body)
            wanted = {int(item) for item in incoming.get("episodeIds") or []}
            touched = set()
            for series_id, episodes in LAB.episodes.items():
                for episode in episodes:
                    if episode["id"] in wanted:
                        episode["monitored"] = bool(incoming.get("monitored"))
                        touched.add(series_id)
            for series_id in touched:
                LAB.refresh_series(series_id)
            self._json([], 202)
            return
        if method == "GET" and path == "/api/v3/release":
            episode_id = (query.get("episodeId") or [None])[0]
            series_id = int((query.get("seriesId") or ["0"])[0])
            season_number = (query.get("seasonNumber") or [None])[0]
            if episode_id:
                self._json(LAB.episode_releases(int(episode_id)))
            elif series_id and season_number is not None:
                self._json(LAB.season_releases(series_id, int(season_number)))
            elif series_id:
                self._json(LAB.series_releases(series_id))
            else:
                self._json([])
            return
        if method == "POST" and path == "/api/v3/release":
            incoming = self._json_body(body)
            meta = LAB.grab(str(incoming.get("guid") or ""))
            if meta is None:
                self._json({"message": "Couldn't find requested release in cache, cache timeout probably expired."}, 404)
                return
            self._json(incoming)
            return
        if method == "GET" and path == "/api/v3/calendar":
            start, end = self._calendar_range(query)
            include_unmonitored = flag(query, "unmonitored", False)
            upcoming = []
            for series_id, episodes in LAB.episodes.items():
                series = LAB.series.get(series_id)
                for episode in episodes:
                    airs = parse_time(episode.get("airDateUtc"))
                    if airs is None or not start <= airs <= end:
                        continue
                    if not include_unmonitored and not (episode.get("monitored") and series and series.get("monitored")):
                        continue
                    copied = copy.deepcopy(episode)
                    if series is not None and flag(query, "includeSeries", False):
                        copied["series"] = self._with_base(series)
                    if not flag(query, "includeEpisodeFile", False):
                        copied.pop("episodeFile", None)
                    upcoming.append(copied)
            self._json(sorted(upcoming, key=lambda item: item["airDateUtc"]))
            return
        if method == "GET" and path == "/api/v3/queue":
            records = []
            for item in LAB.series_queue:
                copied = copy.deepcopy(item)
                series = LAB.series.get(copied.get("seriesId") or 0)
                if series:
                    copied["series"] = self._with_base(series)
                elif not flag(query, "includeUnknownSeriesItems", False):
                    continue
                episode = LAB.episode(copied.get("episodeId") or 0)
                if episode:
                    copied["episode"] = copy.deepcopy(episode)
                records.append(copied)
            self._json(self._page(records, query))
            return
        if method == "GET" and path == "/api/v3/history":
            names = self._history_names(query)
            episode_filter = (query.get("episodeId") or [None])[0]
            series_filter = (query.get("seriesIds") or query.get("seriesId") or [None])[0]
            records = []
            for event in LAB.series_history:
                if names is not None and event["eventType"] not in names:
                    continue
                if episode_filter and str(event.get("episodeId")) != episode_filter:
                    continue
                if series_filter and str(event.get("seriesId")) != series_filter:
                    continue
                copied = copy.deepcopy(event)
                series = LAB.series.get(copied.get("seriesId") or 0)
                if series and flag(query, "includeSeries", False):
                    copied["series"] = self._with_base(series)
                episode = LAB.episode(copied.get("episodeId") or 0)
                if episode and flag(query, "includeEpisode", False):
                    copied["episode"] = copy.deepcopy(episode)
                records.append(copied)
            self._json(self._page(records, query, sort_by_date="date"))
            return
        if method == "GET" and path == "/api/v3/history/series":
            series_id = int((query.get("seriesId") or ["0"])[0])
            season_filter = (query.get("seasonNumber") or [None])[0]
            names = self._history_names(query)
            events = []
            for event in LAB.series_history:
                if event.get("seriesId") != series_id or (names is not None and event["eventType"] not in names):
                    continue
                episode = LAB.episode(event.get("episodeId") or 0)
                if season_filter is not None and (episode is None or str(episode["seasonNumber"]) != season_filter):
                    continue
                events.append(event)
            self._json(sorted(events, key=lambda item: item["date"], reverse=True))
            return
        if method == "GET" and path == "/api/v3/episodefile":
            series_id = int((query.get("seriesId") or ["0"])[0])
            files = {}
            for episode in LAB.episodes.get(series_id, []):
                if episode.get("episodeFile"):
                    files[episode["episodeFile"]["id"]] = episode["episodeFile"]
            self._json(list(files.values()))
            return
        if method == "GET" and re.fullmatch(r"/api/v3/episodefile/\d+", path):
            file_id = int(path.rsplit("/", 1)[-1])
            for episodes in LAB.episodes.values():
                for episode in episodes:
                    current = episode.get("episodeFile") or {}
                    if current.get("id") == file_id:
                        self._json(current)
                        return
            self._not_found()
            return
        if method == "DELETE" and re.fullmatch(r"/api/v3/episodefile/\d+", path):
            if self._delete_episode_files([int(path.rsplit("/", 1)[-1])]):
                self._json({})
            else:
                self._not_found()
            return
        if method == "DELETE" and path == "/api/v3/episodefile/bulk":
            incoming = self._json_body(body)
            self._delete_episode_files(incoming.get("episodeFileIds") or [])
            self._json({})
            return
        if method == "GET" and path == "/api/v3/extrafile":
            series_id = int((query.get("seriesId") or ["0"])[0])
            extras = []
            for episode in LAB.episodes.get(series_id, []):
                file = episode.get("episodeFile")
                if file and not any(item["episodeFileId"] == file["id"] for item in extras):
                    extras.append(
                        {
                            "id": len(extras) + 1,
                            "seriesId": series_id,
                            "seasonNumber": episode["seasonNumber"],
                            "episodeFileId": file["id"],
                            "relativePath": f"Season {episode['seasonNumber']:02d}/{file['relativePath'].rsplit('.', 1)[0]}.en.srt",
                            "extension": ".srt",
                            "type": "subtitle",
                            "languageTags": [],
                            "title": "English",
                        }
                    )
            self._json(extras)
            return
        self._json({"message": f"Unhandled {method} {path}"}, 404)

    def _delete_episode_files(self, file_ids: list) -> bool:
        wanted = {int(file_id) for file_id in file_ids}
        found = False
        for series_id, episodes in LAB.episodes.items():
            touched = False
            for episode in episodes:
                current = episode.get("episodeFile") or {}
                if current.get("id") in wanted:
                    LAB.add_history("sonarr", "episodeFileDeleted", current["relativePath"], series_id=series_id, episode_id=episode["id"], download_id=None, data={"reason": "Manual"})
                    episode["episodeFile"] = None
                    episode["hasFile"] = False
                    episode["episodeFileId"] = 0
                    touched = True
            if touched:
                found = True
                LAB.refresh_series(series_id)
        return found

    def _prowlarr(self, method: str, path: str, query: dict, body: bytes) -> None:
        if method == "GET" and path == "/api/v1/system/status":
            self._json(self._system("Prowlarr", "1.28.2.4885"))
            return
        if method == "GET" and path == "/api/v1/indexer":
            self._json(
                [
                    {"id": 1, "name": "1337x", "protocol": "torrent", "enable": True},
                    {"id": 2, "name": "TorrentDay", "protocol": "torrent", "enable": True},
                    {"id": 3, "name": "EZTV", "protocol": "torrent", "enable": True},
                ]
            )
            return
        if method == "GET" and path == "/api/v1/search":
            term = (query.get("query") or query.get("term") or ["Dune"])[0]
            self._json(
                [
                    release_record("prowlarr-1", f"{term} 2021 Bluray-1080p", indexer="1337x", indexer_id=1),
                    release_record("prowlarr-2", f"{term} 2021 Remux-2160p", indexer="TorrentDay", indexer_id=2),
                ]
            )
            return
        self._json({"message": f"Unhandled {method} {path}"}, 404)

    def _qbit_authorized(self) -> bool:
        header = self.headers.get("Authorization", "")
        if header == f"Bearer {QBIT_BEARER}":
            return True
        cookie = self.headers.get("Cookie", "")
        return f"SID={QBIT_SID}" in cookie

    def _qbit(self, method: str, path: str, query: dict, body: bytes) -> None:
        fields, uploads = self._form(body) if method == "POST" else ({}, [])
        if path == "/api/v2/auth/login" and method == "POST":
            username = (fields.get("username") or [""])[0]
            password = (fields.get("password") or [""])[0]
            if username == QBIT_USER and password == QBIT_PASSWORD:
                self._text(
                    "Ok.",
                    extra={"Set-Cookie": f"SID={QBIT_SID}; Path=/; HttpOnly"},
                )
                return
            self._text("Fails.", 200)
            return
        if not self._qbit_authorized():
            self._text("Forbidden", 403)
            return
        if method == "GET" and path == "/api/v2/app/version":
            self._text("v5.1.2")
            return
        if method == "GET" and path == "/api/v2/app/webapiVersion":
            self._text("2.11.4")
            return
        with LOCK:
            LAB.tick()
            if method == "GET" and path == "/api/v2/torrents/info":
                self._json(self._torrents_info(query))
                return
            if method == "GET" and path == "/api/v2/torrents/properties":
                torrent = LAB.torrent((query.get("hash") or [""])[0])
                if torrent is None:
                    self._text("Not Found", 404)
                    return
                self._json({**torrent, "addition_date": torrent["added_on"], "completion_date": torrent["completion_on"], "total_downloaded": torrent["downloaded"], "total_uploaded": torrent["uploaded"]})
                return
            if method == "GET" and path == "/api/v2/torrents/files":
                infohash = (query.get("hash") or [""])[0].lower()
                if infohash not in LAB.files:
                    self._text("Not Found", 404)
                    return
                self._json(LAB.files[infohash])
                return
            if method == "GET" and path == "/api/v2/sync/torrentPeers":
                torrent = LAB.torrent((query.get("hash") or [""])[0])
                if torrent is None:
                    self._text("Not Found", 404)
                    return
                downloading = torrent["state"] in ("downloading", "forcedDL")
                self._json(
                    {
                        "rid": 1,
                        "full_update": True,
                        "peers": {
                            "203.0.113.10:51413": {
                                "ip": "203.0.113.10",
                                "port": 51413,
                                "connection": "BT",
                                "country_code": "br",
                                "country": "Brazil",
                                "client": "qBittorrent 5.1.2",
                                "peer_id_client": "-qB5120-",
                                "flags": "D" if downloading else "U",
                                "progress": 0.8 if downloading else 0.2,
                                "dl_speed": torrent["dlspeed"],
                                "up_speed": torrent["upspeed"],
                                "downloaded": 2_000_000_000,
                                "uploaded": 30_000_000,
                                "relevance": 1,
                                "files": "",
                            }
                        } if torrent["state"] not in STOPPED_STATES else {},
                    }
                )
                return
            if method == "GET" and path == "/api/v2/torrents/categories":
                self._json(
                    {
                        "radarr": {"name": "radarr", "savePath": "/downloads/radarr"},
                        "sonarr": {"name": "sonarr", "savePath": "/downloads/sonarr"},
                        "cross-seed": {"name": "cross-seed", "savePath": "/downloads/cross-seed"},
                    }
                )
                return
            if method == "GET" and path == "/api/v2/torrents/tags":
                self._json(["arrmate", "cross-seed"])
                return
            if method == "POST":
                self._qbit_action(path, fields, uploads)
                return
        self._text("Not Found", 404)

    def _torrents_info(self, query: dict) -> list[dict]:
        wanted = (query.get("filter") or ["all"])[0]
        category = (query.get("category") or [None])[0]
        tag = (query.get("tag") or [None])[0]
        hashes = {item for value in query.get("hashes") or [] for item in value.lower().split("|") if item}
        checks = {
            "all": lambda item: True,
            "downloading": lambda item: item["state"] in DOWNLOADING_STATES,
            "seeding": lambda item: item["state"] in SEEDING_STATES,
            "completed": lambda item: item["progress"] >= 1,
            "stopped": lambda item: item["state"] in STOPPED_STATES,
            "paused": lambda item: item["state"] in STOPPED_STATES,
            "running": lambda item: item["state"] not in STOPPED_STATES,
            "resumed": lambda item: item["state"] not in STOPPED_STATES,
            "active": lambda item: item["dlspeed"] > 0 or item["upspeed"] > 0,
            "inactive": lambda item: item["dlspeed"] == 0 and item["upspeed"] == 0,
            "stalled": lambda item: item["state"] in ("stalledDL", "stalledUP"),
            "stalled_downloading": lambda item: item["state"] == "stalledDL",
            "stalled_uploading": lambda item: item["state"] == "stalledUP",
            "checking": lambda item: item["state"].startswith("checking"),
            "errored": lambda item: item["state"] in ("error", "missingFiles"),
        }
        check = checks.get(wanted, checks["all"])
        torrents = [
            item
            for item in LAB.torrents
            if check(item)
            and (category is None or item["category"] == category)
            and (tag is None or tag in [part.strip() for part in item["tags"].split(",")])
            and (not hashes or item["hash"] in hashes)
        ]
        return torrents

    def _qbit_action(self, path: str, fields: dict[str, list[str]], uploads: list[tuple[str, bytes]]) -> None:
        hashes = [item.lower() for item in (fields.get("hashes") or [""])[0].split("|") if item]
        selected = LAB.torrents if hashes == ["all"] else [item for item in LAB.torrents if item["hash"] in hashes]
        if path in ("/api/v2/torrents/stop", "/api/v2/torrents/pause"):
            if path.endswith("pause"):
                self._text("Not Found", 404)
                return
            for torrent in selected:
                LAB.apply_state(torrent, "stoppedUP" if torrent["progress"] >= 1 else "stoppedDL")
        elif path in ("/api/v2/torrents/start", "/api/v2/torrents/resume"):
            if path.endswith("resume"):
                self._text("Not Found", 404)
                return
            for torrent in selected:
                if torrent["state"] in STOPPED_STATES or torrent["state"] == "error":
                    stalled = not LAB.sim.get(torrent["hash"], {}).get("auto") and torrent["progress"] >= FIXTURE_STALL_AT
                    LAB.apply_state(torrent, "uploading" if torrent["progress"] >= 1 else "stalledDL" if stalled else "downloading")
        elif path == "/api/v2/torrents/recheck":
            for torrent in selected:
                sim = LAB.sim.setdefault(torrent["hash"], {"auto": False, "speed": 4_000_000})
                after = torrent["state"]
                if after.startswith("checking"):
                    continue
                sim["after_recheck"] = after
                sim["recheck_until"] = time.monotonic() + RECHECK_SECONDS
                LAB.apply_state(torrent, "checkingUP" if torrent["progress"] >= 1 else "checkingDL")
        elif path == "/api/v2/torrents/delete":
            LAB.remove_torrents({item["hash"] for item in selected})
            LAB.sync_queues()
        elif path == "/api/v2/torrents/setLocation":
            location = (fields.get("location") or [""])[0].strip()
            if not location:
                self._text("Save path cannot be empty", 400)
                return
            for torrent in selected:
                torrent["save_path"] = location
                torrent["content_path"] = f"{location}/{torrent['content_path'].rsplit('/', 1)[-1]}"
        elif path == "/api/v2/torrents/filePrio":
            infohash = (fields.get("hash") or [""])[0].lower()
            files = LAB.files.get(infohash)
            torrent = LAB.torrent(infohash)
            if files is None or torrent is None:
                self._text("Not Found", 404)
                return
            try:
                priority = int((fields.get("priority") or [""])[0])
                indexes = [int(item) for item in (fields.get("id") or [""])[0].split("|") if item]
            except ValueError:
                self._text("Bad Request", 400)
                return
            if priority not in (0, 1, 6, 7) or any(index >= len(files) or index < 0 for index in indexes):
                self._text("Conflict", 409)
                return
            for index in indexes:
                files[index]["priority"] = priority
            torrent["size"] = sum(file["size"] for file in files if file["priority"])
        elif path == "/api/v2/torrents/add":
            added = self._add_torrents(fields, uploads)
            if not added:
                self._text("Fails.", 415)
                return
        else:
            self._text("Not Found", 404)
            return
        self._text("Ok.")

    def _add_torrents(self, fields: dict[str, list[str]], uploads: list[tuple[str, bytes]]) -> int:
        category = (fields.get("category") or [""])[0]
        tags = (fields.get("tags") or [""])[0]
        save_path = (fields.get("savepath") or [""])[0] or None
        stopped = (fields.get("stopped") or ["false"])[0].lower() == "true"
        sources: list[tuple[str, str]] = []
        for line in (fields.get("urls") or [""])[0].splitlines():
            line = line.strip()
            if not line:
                continue
            btih = re.search(r"xt=urn:btih:([0-9a-fA-F]{40})", line)
            display = re.search(r"[?&]dn=([^&]+)", line)
            name = unquote_plus(display.group(1)) if display else line.rsplit("/", 1)[-1] or line
            if btih:
                infohash = btih.group(1).lower()
            elif re.fullmatch(r"[0-9a-fA-F]{40}", line):
                infohash = line.lower()
                name = f"Magnet {infohash[:8]}"
            else:
                infohash = hashlib.sha1(line.encode()).hexdigest()
                name = re.sub(r"\.torrent$", "", name)
            sources.append((infohash, name))
        for filename, content in uploads:
            sources.append((hashlib.sha1(content or filename.encode()).hexdigest(), re.sub(r"\.torrent$", "", filename) or "Uploaded torrent"))
        added = 0
        for infohash, name in sources:
            if LAB.torrent(infohash):
                continue
            LAB.add_torrent(
                infohash,
                name[:120],
                state="stoppedDL" if stopped else "downloading",
                progress=0.0,
                category=category,
                tags=tags,
                save_path=save_path,
                size=2_000_000_000,
                auto=True,
                front=True,
            )
            added += 1
        return added


def serve(port: int) -> None:
    """Listen on [port] until the process stops."""
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print(f"[MediaLab] Listening on {port}")
    server.serve_forever()


def main() -> None:
    """Start Radarr, Sonarr, Prowlarr, and qBittorrent listeners."""
    ports = (7878, 8989, 9696, 8080)
    threads = [
        threading.Thread(target=serve, args=(port,), daemon=True, name=f"lab-{port}")
        for port in ports
    ]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()


if __name__ == "__main__":
    main()
