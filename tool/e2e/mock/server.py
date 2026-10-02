#!/usr/bin/env python3
"""Mock Radarr, Sonarr, Prowlarr, and qBittorrent for Arrmate end-to-end tests.

The four APIs share one process so grabbing a release creates a queue item and
a torrent. Posters are generated in-process. No external metadata provider is
required.

Credentials
    Radarr     X-Api-Key: arrmate-radarr     http://127.0.0.1:7878
    Sonarr     X-Api-Key: arrmate-sonarr     http://127.0.0.1:8989
    Prowlarr   X-Api-Key: arrmate-prowlarr   http://127.0.0.1:9696
    qBittorrent  admin:adminarr  or Bearer arrmate-qbit
                 http://127.0.0.1:8080
"""

from __future__ import annotations

import json
import re
import struct
import threading
import zlib
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

RADARR_KEY = "arrmate-radarr"
SONARR_KEY = "arrmate-sonarr"
PROWLARR_KEY = "arrmate-prowlarr"
QBIT_USER = "admin"
QBIT_PASSWORD = "adminarr"
QBIT_BEARER = "arrmate-qbit"
QBIT_SID = "arrmate-lab"

LOCK = threading.Lock()
NOW = datetime.now(timezone.utc)


def iso(moment: datetime) -> str:
    """Return an ISO-8601 timestamp the Dart parsers accept."""
    return moment.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def quality(name: str = "Bluray-1080p", quality_id: int = 7, resolution: int = 1080) -> dict:
    """Build a Radarr/Sonarr quality object."""
    return {
        "quality": {
            "id": quality_id,
            "name": name,
            "source": "bluray",
            "resolution": resolution,
        },
        "revision": {"version": 1, "real": 0, "isRepack": False},
    }


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
    genres: list[str] | None = None,
    studio: str = "Arrmate Pictures",
    base: str = "http://127.0.0.1:7878",
) -> dict:
    """Serialize one movie the way Radarr's v3 resource does."""
    added = iso(NOW - timedelta(days=12))
    record = {
        "id": movie_id if in_library else 0,
        "tmdbId": tmdb_id,
        "imdbId": f"tt{tmdb_id:07d}",
        "title": title,
        "sortTitle": title.lower(),
        "studio": studio,
        "year": year,
        "runtime": 128,
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
        "isAvailable": status == "released",
        "minimumAvailability": "released",
        "monitored": monitored,
        "qualityProfileId": 1,
        "sizeOnDisk": 8_000_000_000 if has_file else 0,
        "hasFile": has_file,
        "path": f"/movies/{title} ({year})" if in_library else None,
        "folderName": f"{title} ({year})",
        "rootFolderPath": "/movies",
        "added": added,
        "inCinemas": iso(in_cinemas or datetime(year, 6, 1, tzinfo=timezone.utc)),
        "physicalRelease": iso(datetime(year, 9, 1, tzinfo=timezone.utc)),
        "digitalRelease": iso(datetime(year, 8, 15, tzinfo=timezone.utc)),
        "tags": [1],
        "images": images_for(tmdb_id, base),
    }
    if has_file:
        record["movieFile"] = media_file(
            1000 + movie_id,
            f"{title} ({year}) Bluray-1080p.mkv",
            f"/movies/{title} ({year})",
        )
    return record


def media_file(file_id: int, name: str, folder: str) -> dict:
    """Serialize a movie or episode file."""
    return {
        "id": file_id,
        "relativePath": name,
        "path": f"{folder}/{name}",
        "size": 4_000_000_000,
        "dateAdded": iso(NOW - timedelta(days=3)),
        "quality": HD,
        "languages": [ENGLISH],
        "customFormats": [{"id": 1, "name": "HDR"}],
        "customFormatScore": 100,
        "mediaInfo": {
            "audioCodec": "EAC3",
            "videoCodec": "x265",
            "resolution": "1080p",
        },
    }


def season(number: int, episodes: int, files: int) -> dict:
    """Serialize one season with progress statistics."""
    percent = 0 if episodes == 0 else round(files / episodes * 100, 1)
    return {
        "seasonNumber": number,
        "monitored": True,
        "statistics": {
            "episodeCount": episodes,
            "episodeFileCount": files,
            "totalEpisodeCount": episodes,
            "percentOfEpisodes": percent,
            "sizeOnDisk": files * 1_500_000_000,
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
    status: str = "continuing",
    episode_files: int = 4,
    episode_count: int = 9,
    network: str = "Apple TV+",
    base: str = "http://127.0.0.1:8989",
    next_airing: datetime | None = None,
) -> dict:
    """Serialize one series the way Sonarr's v3 resource does."""
    percent = 0 if episode_count == 0 else round(episode_files / episode_count * 100, 1)
    return {
        "id": series_id if in_library else 0,
        "title": title,
        "titleSlug": title.lower().replace(" ", "-"),
        "sortTitle": title.lower(),
        "tvdbId": tvdb_id,
        "tvMazeId": tvdb_id,
        "imdbId": f"tt{tvdb_id:07d}",
        "tmdbId": tvdb_id,
        "status": status,
        "seriesType": "standard",
        "path": f"/tv/{title} ({year})" if in_library else None,
        "folder": f"{title} ({year})",
        "qualityProfileId": 1,
        "rootFolderPath": "/tv",
        "certification": "TV-MA",
        "year": year,
        "runtime": 48,
        "airTime": "21:00",
        "ended": status == "ended",
        "seasonFolder": True,
        "useSceneNumbering": False,
        "added": iso(NOW - timedelta(days=20)),
        "firstAired": iso(datetime(year, 2, 1, tzinfo=timezone.utc)),
        "nextAiring": iso(next_airing) if next_airing else None,
        "monitored": True,
        "monitorNewItems": "all",
        "overview": overview,
        "network": network,
        "originalLanguage": ENGLISH,
        "alternateTitles": [],
        "seasons": [season(1, episode_count, episode_files)],
        "tags": [1],
        "genres": ["Drama", "Science Fiction"],
        "images": images_for(tvdb_id, base),
        "ratings": {"votes": 40000, "value": 8.4},
        "statistics": {
            "sizeOnDisk": episode_files * 1_500_000_000,
            "seasonCount": 1,
            "episodeCount": episode_count,
            "episodeFileCount": episode_files,
            "totalEpisodeCount": episode_count,
            "percentOfEpisodes": percent,
        },
    }


def episode_record(
    episode_id: int,
    series_id: int,
    season_number: int,
    number: int,
    title: str,
    *,
    has_file: bool,
    airs: datetime,
) -> dict:
    """Serialize one episode."""
    record = {
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
        "hasFile": has_file,
        "monitored": True,
        "episodeFileId": 5000 + episode_id if has_file else None,
    }
    if has_file:
        record["episodeFile"] = media_file(
            5000 + episode_id,
            f"S{season_number:02d}E{number:02d} - {title}.mkv",
            f"/tv/series-{series_id}",
        )
    return record


def release_record(
    guid: str,
    title: str,
    *,
    indexer: str,
    indexer_id: int,
    rejected: bool = False,
    seeders: int = 40,
) -> dict:
    """Serialize an interactive-search release attributed to Prowlarr."""
    return {
        "guid": guid,
        "title": title,
        "size": 6_000_000_000,
        "link": f"http://127.0.0.1:9696/download/{guid}",
        "indexer": f"{indexer} (Prowlarr)",
        "indexerId": indexer_id,
        "seeders": seeders,
        "leechers": 3,
        "protocol": "torrent",
        "rejected": rejected,
        "rejections": ["Release is below the quality cutoff"] if rejected else [],
        "age": 2,
        "indexerFlags": ["freeleech"] if not rejected else [],
        "infoUrl": f"http://127.0.0.1:9696/info/{guid}",
        "downloadUrl": f"magnet:?xt=urn:btih:{guid[:40]}",
        "customFormatScore": 50,
        "qualityWeight": 100,
        "releaseWeight": 10,
        "languages": [ENGLISH],
        "customFormats": [{"id": 1, "name": "HDR"}],
        "mappedEpisodeNumbers": [],
        "fullSeason": False,
        "episodeRequested": False,
        "quality": HD,
    }


class Lab:
    """In-memory library shared by every mocked service."""

    def __init__(self) -> None:
        soon = NOW + timedelta(days=10)
        self.movies: dict[int, dict] = {}
        self.catalog_movies = [
            self._store_movie(
                movie_record(
                    1,
                    438631,
                    "Dune",
                    2021,
                    "Paul Atreides arrives on Arrakis and learns the desert keeps its own secrets.",
                    in_library=True,
                    has_file=True,
                    genres=["Science Fiction", "Adventure"],
                )
            ),
            self._store_movie(
                movie_record(
                    2,
                    603,
                    "The Matrix",
                    1999,
                    "A hacker discovers the world he knows is a simulation and chooses the red pill.",
                    in_library=True,
                    has_file=True,
                    genres=["Action", "Science Fiction"],
                )
            ),
            self._store_movie(
                movie_record(
                    3,
                    329865,
                    "Arrival",
                    2016,
                    "A linguist tries to understand visitors whose language rewrites time.",
                    in_library=True,
                    has_file=False,
                    genres=["Drama", "Science Fiction"],
                )
            ),
            self._store_movie(
                movie_record(
                    4,
                    872585,
                    "Oppenheimer",
                    2023,
                    "A physicist builds the weapon that ends one war and starts another kind of fear.",
                    in_library=True,
                    has_file=False,
                    status="inCinemas",
                    in_cinemas=soon,
                    genres=["Drama", "History"],
                )
            ),
        ]
        self.lookup_movies = [
            movie_record(
                0,
                27205,
                "Inception",
                2010,
                "A thief enters dreams to plant an idea and risks losing the exit.",
                in_library=False,
                genres=["Action", "Science Fiction"],
            ),
            movie_record(
                0,
                335984,
                "Blade Runner 2049",
                2017,
                "A replicant hunts a secret that could change what it means to be human.",
                in_library=False,
                genres=["Science Fiction", "Mystery"],
            ),
        ]
        self.series: dict[int, dict] = {}
        self.catalog_series = [
            self._store_series(
                series_record(
                    1,
                    371980,
                    "Severance",
                    2022,
                    "Office workers split their memories between the desk and the life outside.",
                    in_library=True,
                    episode_files=4,
                    episode_count=9,
                    next_airing=NOW + timedelta(days=4),
                )
            ),
            self._store_series(
                series_record(
                    2,
                    393189,
                    "The Bear",
                    2022,
                    "A fine-dining chef inherits a Chicago sandwich shop and the family that runs it.",
                    in_library=True,
                    episode_files=8,
                    episode_count=8,
                    status="ended",
                    network="FX",
                )
            ),
        ]
        self.lookup_series = [
            series_record(
                0,
                417742,
                "Shogun",
                2024,
                "A shipwrecked sailor becomes a pawn in a war for feudal Japan.",
                in_library=False,
                network="FX",
                episode_files=0,
                episode_count=10,
            )
        ]
        self.episodes = {
            1: [
                episode_record(
                    11,
                    1,
                    1,
                    1,
                    "Good News About Hell",
                    has_file=True,
                    airs=datetime(2022, 2, 18, tzinfo=timezone.utc),
                ),
                episode_record(
                    12,
                    1,
                    1,
                    2,
                    "Half Loop",
                    has_file=True,
                    airs=datetime(2022, 2, 25, tzinfo=timezone.utc),
                ),
                episode_record(
                    13,
                    1,
                    1,
                    9,
                    "The We We Are",
                    has_file=False,
                    airs=NOW + timedelta(days=4),
                ),
            ],
            2: [
                episode_record(
                    21,
                    2,
                    1,
                    1,
                    "System",
                    has_file=True,
                    airs=datetime(2022, 6, 23, tzinfo=timezone.utc),
                )
            ],
        }
        self.next_movie_id = 10
        self.next_series_id = 10
        self.next_history_id = 100
        self.next_queue_id = 50
        self.next_command_id = 1
        self.notifications: list[dict] = []
        matrix_hash = "a" * 40
        matrix_cross = "b" * 40
        dune_hash = "c" * 40
        arrival_hash = "d" * 40
        orphan_hash = "e" * 40
        error_hash = "f" * 40
        self.torrents = [
            self._torrent(
                dune_hash,
                "Dune 2021 Bluray-1080p",
                state="downloading",
                progress=0.42,
                category="radarr",
            ),
            self._torrent(
                matrix_hash,
                "The Matrix 1999 Bluray-1080p",
                state="uploading",
                progress=1,
                category="radarr",
            ),
            self._torrent(
                matrix_cross,
                "The Matrix 1999 Bluray-1080p",
                state="uploading",
                progress=1,
                category="cross-seed",
            ),
            self._torrent(
                arrival_hash,
                "Arrival 2016 WEBDL-1080p",
                state="pausedDL",
                progress=0.15,
                category="radarr",
            ),
            self._torrent(
                error_hash,
                "Broken Sample WEBDL-720p",
                state="error",
                progress=0.05,
                category="radarr",
            ),
            self._torrent(
                orphan_hash,
                "Unrelated Concert Bootleg 2020",
                state="uploading",
                progress=1,
                category="",
            ),
        ]
        self.history = [
            self._history(
                1,
                "grabbed",
                "The Matrix 1999 Bluray-1080p",
                movie_id=2,
                download_id=matrix_hash,
                when=NOW - timedelta(days=6),
            ),
            self._history(
                2,
                "downloadFolderImported",
                "The Matrix 1999 Bluray-1080p",
                movie_id=2,
                download_id=matrix_hash,
                when=NOW - timedelta(days=5),
            ),
            self._history(
                3,
                "downloadFailed",
                "Arrival 2016 WEBDL-1080p",
                movie_id=3,
                download_id=arrival_hash,
                when=NOW - timedelta(days=1),
            ),
            self._history(
                4,
                "grabbed",
                "Severance S01E01 Good News About Hell",
                series_id=1,
                episode_id=11,
                download_id="9" * 40,
                when=NOW - timedelta(days=8),
            ),
        ]
        self.queue = [
            self._queue(
                1,
                "Dune 2021 Bluray-1080p",
                movie_id=1,
                download_id=dune_hash,
                status="downloading",
                tracked="ok",
                state="downloading",
                sizeleft=3_000_000_000,
            ),
            self._queue(
                2,
                "Arrival 2016 WEBDL-1080p",
                movie_id=3,
                download_id=arrival_hash,
                status="warning",
                tracked="warning",
                state="importPending",
                sizeleft=0,
            ),
        ]
        self.series_history = [
            self._history(
                4,
                "grabbed",
                "Severance S01E01 Good News About Hell",
                series_id=1,
                episode_id=11,
                download_id="9" * 40,
                when=NOW - timedelta(days=8),
            ),
            self._history(
                5,
                "downloadFolderImported",
                "Severance S01E01 Good News About Hell",
                series_id=1,
                episode_id=11,
                download_id="9" * 40,
                when=NOW - timedelta(days=7),
            ),
        ]
        self.series_queue = [
            self._queue(
                3,
                "Severance S01E09 The We We Are",
                series_id=1,
                episode_id=13,
                download_id="8" * 40,
                status="downloading",
                tracked="ok",
                state="downloading",
                sizeleft=800_000_000,
                season_number=1,
            )
        ]
        self.torrents.append(
            self._torrent(
                "8" * 40,
                "Severance S01E09 The We We Are",
                state="downloading",
                progress=0.6,
                category="sonarr",
            )
        )
        self.torrents.append(
            self._torrent(
                "9" * 40,
                "Severance S01E01 Good News About Hell",
                state="uploading",
                progress=1,
                category="sonarr",
            )
        )

    def _store_movie(self, record: dict) -> dict:
        self.movies[record["id"]] = record
        return record

    def _store_series(self, record: dict) -> dict:
        self.series[record["id"]] = record
        return record

    def _torrent(
        self,
        infohash: str,
        name: str,
        *,
        state: str,
        progress: float,
        category: str,
    ) -> dict:
        size = 6_000_000_000
        return {
            "hash": infohash,
            "name": name,
            "size": size,
            "progress": progress,
            "dlspeed": 4_000_000 if state == "downloading" else 0,
            "upspeed": 200_000 if progress >= 1 else 0,
            "eta": 900 if state == "downloading" else 8640000,
            "ratio": 1.4 if progress >= 1 else 0.1,
            "state": state,
            "category": category,
            "tags": "arrmate,cross-seed" if category == "cross-seed" else "arrmate",
            "save_path": f"/downloads/{category or 'manual'}",
            "num_seeds": 12,
            "num_leechs": 3,
            "downloaded": int(size * progress),
            "uploaded": int(size * 0.2),
            "amount_left": int(size * (1 - progress)),
            "added_on": int((NOW - timedelta(days=2)).timestamp()),
            "priority": 1,
            "seeding_time": 86_400 if progress >= 1 else 0,
            "completion_on": int(NOW.timestamp()) if progress >= 1 else 0,
        }

    def _history(
        self,
        event_id: int,
        event_type: str,
        title: str,
        *,
        movie_id: int | None = None,
        series_id: int | None = None,
        episode_id: int | None = None,
        download_id: str,
        when: datetime,
    ) -> dict:
        return {
            "id": event_id,
            "eventType": event_type,
            "date": iso(when),
            "sourceTitle": title,
            "movieId": movie_id,
            "seriesId": series_id,
            "episodeId": episode_id,
            "quality": HD,
            "languages": [ENGLISH],
            "customFormats": [{"id": 1, "name": "HDR"}],
            "customFormatScore": 50,
            "downloadId": download_id,
            "data": {"indexer": "1337x (Prowlarr)", "downloadClient": "qBittorrent"},
        }

    def _queue(
        self,
        item_id: int,
        title: str,
        *,
        movie_id: int | None = None,
        series_id: int | None = None,
        episode_id: int | None = None,
        download_id: str,
        status: str,
        tracked: str,
        state: str,
        sizeleft: int,
        season_number: int | None = None,
    ) -> dict:
        return {
            "id": item_id,
            "movieId": movie_id,
            "seriesId": series_id,
            "episodeId": episode_id,
            "seasonNumber": season_number,
            "title": title,
            "indexer": "1337x (Prowlarr)",
            "added": iso(NOW - timedelta(hours=3)),
            "quality": HD,
            "languages": [ENGLISH],
            "customFormats": [{"id": 1, "name": "HDR"}],
            "customFormatScore": 50,
            "status": status,
            "trackedDownloadStatus": tracked,
            "trackedDownloadState": state,
            "statusMessages": [],
            "errorMessage": None,
            "downloadId": download_id,
            "protocol": "torrent",
            "downloadClient": "qBittorrent",
            "outputPath": f"/downloads/{title}",
            "size": 6_000_000_000,
            "sizeleft": sizeleft,
            "estimatedCompletionTime": iso(NOW + timedelta(minutes=20)),
            "progress": 0 if sizeleft == 0 else 55,
        }

    def movie_releases(self, movie_id: int) -> list[dict]:
        movie = self.movies.get(movie_id)
        title = movie["title"] if movie else "Unknown"
        year = movie["year"] if movie else 2024
        return [
            release_record(
                f"movie-{movie_id}-1080",
                f"{title} {year} Bluray-1080p",
                indexer="1337x",
                indexer_id=1,
            ),
            release_record(
                f"movie-{movie_id}-2160",
                f"{title} {year} Remux-2160p",
                indexer="TorrentDay",
                indexer_id=2,
                seeders=8,
            ),
            release_record(
                f"movie-{movie_id}-720",
                f"{title} {year} WEBDL-720p",
                indexer="EZTV",
                indexer_id=3,
                rejected=True,
                seeders=2,
            ),
        ]

    def series_releases(self, series_id: int) -> list[dict]:
        series = self.series.get(series_id)
        title = series["title"] if series else "Unknown"
        return [
            release_record(
                f"series-{series_id}-s01",
                f"{title} S01 1080p BluRay",
                indexer="1337x",
                indexer_id=1,
            ),
            release_record(
                f"series-{series_id}-e01",
                f"{title} S01E01 1080p WEB",
                indexer="TorrentDay",
                indexer_id=2,
            ),
        ]

    def grab(self, guid: str, *, movies: bool) -> None:
        """Send a release to the mocked download client and the activity queue."""
        title = guid
        media_id = 0
        if movies:
            for movie_id in self.movies:
                for release in self.movie_releases(movie_id):
                    if release["guid"] == guid:
                        title = release["title"]
                        media_id = movie_id
        else:
            for series_id in self.series:
                for release in self.series_releases(series_id):
                    if release["guid"] == guid:
                        title = release["title"]
                        media_id = series_id
        infohash = (guid.replace("-", "") + "0" * 40)[:40]
        if not any(item["hash"] == infohash for item in self.torrents):
            self.torrents.insert(
                0,
                self._torrent(
                    infohash,
                    title,
                    state="downloading",
                    progress=0.05,
                    category="radarr" if movies else "sonarr",
                ),
            )
        self.next_queue_id += 1
        self.next_history_id += 1
        item = self._queue(
            self.next_queue_id,
            title,
            movie_id=media_id if movies else None,
            series_id=None if movies else media_id,
            download_id=infohash,
            status="queued",
            tracked="ok",
            state="downloading",
            sizeleft=5_000_000_000,
        )
        (self.queue if movies else self.series_queue).insert(0, item)
        event = self._history(
            self.next_history_id,
            "grabbed",
            title,
            movie_id=media_id if movies else None,
            series_id=None if movies else media_id,
            download_id=infohash,
            when=NOW,
        )
        (self.history if movies else self.series_history).insert(0, event)


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
        if self.role == "radarr":
            self._radarr(method, path, query, body)
        elif self.role == "sonarr":
            self._sonarr(method, path, query, body)
        else:
            self._prowlarr(method, path, query, body)

    def _authorized(self) -> bool:
        expected = {
            "radarr": RADARR_KEY,
            "sonarr": SONARR_KEY,
            "prowlarr": PROWLARR_KEY,
        }[self.role]
        return self.headers.get("X-Api-Key") == expected

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

    def _form(self, body: bytes) -> dict[str, list[str]]:
        content_type = self.headers.get("Content-Type", "")
        if "multipart/form-data" in content_type:
            match = re.search(r"boundary=([^;]+)", content_type)
            boundary = match.group(1).strip().strip('"') if match else ""
            fields: dict[str, list[str]] = {}
            for chunk in body.split(f"--{boundary}".encode()):
                found = re.search(br'name="([^"]+)"', chunk)
                if not found or b"\r\n\r\n" not in chunk:
                    continue
                value = chunk.split(b"\r\n\r\n", 1)[1]
                value = value.rsplit(b"\r\n", 1)[0]
                fields.setdefault(found.group(1).decode(), []).append(
                    value.decode(errors="replace")
                )
            return fields
        parsed = parse_qs(body.decode(errors="replace"), keep_blank_values=True)
        return parsed

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

    def _cover(self, path: str) -> None:
        parts = [part for part in path.split("/") if part]
        seed = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 1
        wide = "fanart" in path
        self._send(200, cover_bytes(seed, wide), "image/png")

    def _history_names(self, query: dict) -> set[str] | None:
        """Map Radarr/Sonarr numeric history filters onto fixture event names."""
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
            "2": {"downloadFolderImported"},
            "3": {"seriesFolderImported", "downloadFolderImported"},
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

    def _page(self, records: list, query: dict) -> dict:
        page = int((query.get("page") or ["1"])[0])
        page_size = int((query.get("pageSize") or ["50"])[0])
        names = self._history_names(query)
        filtered = records
        if names is not None:
            filtered = [item for item in records if item.get("eventType") in names]
        start = (page - 1) * page_size
        return {
            "page": page,
            "pageSize": page_size,
            "sortKey": (query.get("sortKey") or ["date"])[0],
            "sortDirection": (query.get("sortDirection") or ["descending"])[0],
            "totalRecords": len(filtered),
            "records": filtered[start : start + page_size],
        }

    def _with_base(self, record: dict, base: str, kind: str) -> dict:
        copied = json.loads(json.dumps(record))
        seed = copied.get("tmdbId") or copied.get("tvdbId") or copied.get("id") or 1
        copied["images"] = images_for(int(seed), base)
        if kind == "movie" and copied.get("movieFile"):
            copied["movieFile"]["quality"] = HD
        return copied

    def _system(self, app_name: str, version: str) -> dict:
        return {
            "appName": app_name,
            "instanceName": f"Arrmate Lab {app_name}",
            "version": version,
            "isDebug": True,
            "authentication": "forms",
            "startTime": iso(NOW),
            "urlBase": "",
        }

    def _common_gets(self, path: str, query: dict, app_name: str, version: str) -> bool:
        if path == "/api/v3/system/status":
            self._json(self._system(app_name, version))
            return True
        if path == "/api/v3/diskspace":
            self._json(
                [
                    {
                        "path": "/movies" if app_name == "Radarr" else "/tv",
                        "label": "Media",
                        "freeSpace": 800_000_000_000,
                        "totalSpace": 2_000_000_000_000,
                    }
                ]
            )
            return True
        if path == "/api/v3/qualityprofile":
            self._json(
                [{"id": 1, "name": "HD-1080p"}, {"id": 2, "name": "Ultra-HD"}]
            )
            return True
        if path == "/api/v3/rootfolder":
            folder = "/movies" if app_name == "Radarr" else "/tv"
            self._json(
                [
                    {
                        "id": 1,
                        "path": folder,
                        "accessible": True,
                        "freeSpace": 800_000_000_000,
                    }
                ]
            )
            return True
        if path == "/api/v3/health":
            self._json(
                [
                    {
                        "source": "DownloadClientCheck",
                        "type": "warning",
                        "message": "qBittorrent is the Arrmate lab mock. Downloads are simulated.",
                        "wikiUrl": "https://wiki.servarr.com/",
                    }
                ]
            )
            return True
        if path == "/api/v3/log":
            self._json(
                self._page(
                    [
                        {
                            "time": iso(NOW),
                            "level": "info",
                            "logger": app_name,
                            "message": "Media lab started with sample library data.",
                        }
                    ],
                    query,
                )
            )
            return True
        if path == "/api/v3/tag":
            self._json([{"id": 1, "label": "lab"}])
            return True
        if path == "/api/v3/downloadclient":
            category = "movieCategory" if app_name == "Radarr" else "tvCategory"
            value = "radarr" if app_name == "Radarr" else "sonarr"
            self._json(
                [
                    {
                        "id": 1,
                        "name": "qBittorrent",
                        "implementation": "QBittorrent",
                        "enable": True,
                        "protocol": "torrent",
                        "fields": [{"name": category, "value": value}],
                    }
                ]
            )
            return True
        if path == "/api/v3/notification/schema":
            self._json(
                [
                    {
                        "name": "ntfy",
                        "implementation": "Ntfy",
                        "configContract": "NtfySettings",
                        "fields": [
                            {"name": "serverUrl", "value": "https://ntfy.sh"},
                            {"name": "topics", "value": "arrmate-lab"},
                        ],
                    }
                ]
            )
            return True
        if path == "/api/v3/notification":
            self._json(LAB.notifications)
            return True
        return False

    def _radarr(self, method: str, path: str, query: dict, body: bytes) -> None:
        base = self._base()
        if method == "GET" and self._common_gets(path, query, "Radarr", "5.18.4.9674"):
            return
        with LOCK:
            if method == "GET" and path == "/api/v3/movie":
                self._json(
                    [self._with_base(movie, base, "movie") for movie in LAB.movies.values()]
                )
                return
            if method == "GET" and path == "/api/v3/movie/lookup":
                term = (query.get("term") or [""])[0].lower()
                pool = list(LAB.movies.values()) + LAB.lookup_movies
                matched = [
                    self._with_base(movie, base, "movie")
                    for movie in pool
                    if term in movie["title"].lower() or term in (movie.get("overview") or "").lower()
                ]
                self._json(matched)
                return
            if method == "GET" and re.fullmatch(r"/api/v3/movie/\d+", path):
                movie_id = int(path.rsplit("/", 1)[-1])
                movie = LAB.movies.get(movie_id)
                if movie is None:
                    self._json({"message": "Not found"}, 404)
                    return
                self._json(self._with_base(movie, base, "movie"))
                return
            if method == "POST" and path == "/api/v3/movie":
                incoming = self._json_body(body)
                LAB.next_movie_id += 1
                movie_id = LAB.next_movie_id
                title = incoming.get("title") or "Untitled"
                year = int(incoming.get("year") or NOW.year)
                created = movie_record(
                    movie_id,
                    int(incoming.get("tmdbId") or movie_id),
                    title,
                    year,
                    incoming.get("overview") or "Added from the Arrmate lab lookup.",
                    in_library=True,
                    monitored=bool(incoming.get("monitored", True)),
                    base=base,
                )
                created["qualityProfileId"] = incoming.get("qualityProfileId") or 1
                created["rootFolderPath"] = incoming.get("rootFolderPath") or "/movies"
                LAB.movies[movie_id] = created
                self._json(self._with_base(created, base, "movie"))
                return
            if method == "PUT" and path == "/api/v3/movie/editor":
                incoming = self._json_body(body)
                for movie_id in incoming.get("movieIds") or []:
                    movie = LAB.movies.get(int(movie_id))
                    if movie is None:
                        continue
                    for key in ("monitored", "qualityProfileId", "rootFolderPath", "tags"):
                        if key in incoming:
                            movie[key] = incoming[key]
                self._json({})
                return
            if method == "DELETE" and re.fullmatch(r"/api/v3/movie/\d+", path):
                LAB.movies.pop(int(path.rsplit("/", 1)[-1]), None)
                self._json({})
                return
            if method == "GET" and path == "/api/v3/release":
                movie_id = int((query.get("movieId") or ["0"])[0])
                self._json(LAB.movie_releases(movie_id))
                return
            if method == "POST" and path == "/api/v3/release":
                incoming = self._json_body(body)
                LAB.grab(str(incoming.get("guid") or ""), movies=True)
                self._json({})
                return
            if method == "GET" and path == "/api/v3/calendar":
                upcoming = [
                    self._with_base(movie, base, "movie")
                    for movie in LAB.movies.values()
                    if movie.get("status") == "inCinemas" or not movie.get("hasFile")
                ]
                self._json(upcoming)
                return
            if method == "GET" and path == "/api/v3/queue":
                records = []
                for item in LAB.queue:
                    copied = json.loads(json.dumps(item))
                    movie = LAB.movies.get(copied.get("movieId") or 0)
                    if movie:
                        copied["movie"] = self._with_base(movie, base, "movie")
                    records.append(copied)
                self._json(self._page(records, query))
                return
            if method == "DELETE" and re.fullmatch(r"/api/v3/queue/\d+", path):
                item_id = int(path.rsplit("/", 1)[-1])
                LAB.queue = [item for item in LAB.queue if item["id"] != item_id]
                self._json({})
                return
            if method == "GET" and path == "/api/v3/history":
                records = []
                for event in LAB.history:
                    copied = json.loads(json.dumps(event))
                    movie = LAB.movies.get(copied.get("movieId") or 0)
                    if movie and (query.get("includeMovie") or ["false"])[0] == "true":
                        copied["movie"] = self._with_base(movie, base, "movie")
                    records.append(copied)
                self._json(self._page(records, query))
                return
            if method == "GET" and path == "/api/v3/history/movie":
                movie_id = int((query.get("movieId") or ["0"])[0])
                self._json(
                    [event for event in LAB.history if event.get("movieId") == movie_id]
                )
                return
            if method == "GET" and path == "/api/v3/moviefile":
                movie_id = int((query.get("movieId") or ["0"])[0])
                movie = LAB.movies.get(movie_id)
                files = [movie["movieFile"]] if movie and movie.get("movieFile") else []
                self._json(files)
                return
            if method == "DELETE" and re.fullmatch(r"/api/v3/moviefile/\d+", path):
                file_id = int(path.rsplit("/", 1)[-1])
                for movie in LAB.movies.values():
                    current = movie.get("movieFile") or {}
                    if current.get("id") == file_id:
                        movie["movieFile"] = None
                        movie["hasFile"] = False
                        movie["sizeOnDisk"] = 0
                self._json({})
                return
            if method == "GET" and path == "/api/v3/extrafile":
                movie_id = int((query.get("movieId") or ["0"])[0])
                self._json(
                    [
                        {
                            "id": 1,
                            "movieId": movie_id,
                            "relativePath": "subs/english.srt",
                            "extension": ".srt",
                            "type": "subtitle",
                        }
                    ]
                )
                return
            if method == "GET" and path == "/api/v3/manualimport":
                download_id = (query.get("downloadId") or [""])[0]
                movie = LAB.movies.get(3) or next(iter(LAB.movies.values()), None)
                self._json(
                    [
                        {
                            "id": 1,
                            "name": "Arrival 2016 WEBDL-1080p.mkv",
                            "path": "/downloads/Arrival 2016 WEBDL-1080p.mkv",
                            "relativePath": "Arrival 2016 WEBDL-1080p.mkv",
                            "folderName": "Arrival 2016 WEBDL-1080p",
                            "size": 4_000_000_000,
                            "quality": HD,
                            "languages": [ENGLISH],
                            "releaseGroup": "LAB",
                            "downloadId": download_id or "d" * 40,
                            "movie": self._with_base(movie, base, "movie") if movie else None,
                            "rejections": [],
                        }
                    ]
                )
                return
            if method == "POST" and path == "/api/v3/command":
                incoming = self._json_body(body)
                LAB.next_command_id += 1
                self._json(
                    {
                        "id": LAB.next_command_id,
                        "name": incoming.get("name"),
                        "status": "completed",
                    }
                )
                return
            if method == "GET" and re.fullmatch(r"/api/v3/command/\d+", path):
                self._json({"id": int(path.rsplit("/", 1)[-1]), "status": "completed"})
                return
            if method == "POST" and path == "/api/v3/notification":
                incoming = self._json_body(body)
                incoming["id"] = len(LAB.notifications) + 1
                LAB.notifications.append(incoming)
                self._json(incoming)
                return
        self._json({"message": f"Unhandled {method} {path}"}, 404)

    def _sonarr(self, method: str, path: str, query: dict, body: bytes) -> None:
        base = self._base()
        if method == "GET" and self._common_gets(path, query, "Sonarr", "4.0.14.2939"):
            return
        with LOCK:
            if method == "GET" and path == "/api/v3/series":
                self._json(
                    [self._with_base(item, base, "series") for item in LAB.series.values()]
                )
                return
            if method == "GET" and path == "/api/v3/series/lookup":
                term = (query.get("term") or [""])[0].lower()
                pool = list(LAB.series.values()) + LAB.lookup_series
                self._json(
                    [
                        self._with_base(item, base, "series")
                        for item in pool
                        if term in item["title"].lower()
                        or term in (item.get("overview") or "").lower()
                    ]
                )
                return
            if method == "GET" and re.fullmatch(r"/api/v3/series/\d+", path):
                series_id = int(path.rsplit("/", 1)[-1])
                item = LAB.series.get(series_id)
                if item is None:
                    self._json({"message": "Not found"}, 404)
                    return
                self._json(self._with_base(item, base, "series"))
                return
            if method == "POST" and path == "/api/v3/series":
                incoming = self._json_body(body)
                LAB.next_series_id += 1
                series_id = LAB.next_series_id
                title = incoming.get("title") or "Untitled"
                created = series_record(
                    series_id,
                    int(incoming.get("tvdbId") or series_id),
                    title,
                    int(incoming.get("year") or NOW.year),
                    incoming.get("overview") or "Added from the Arrmate lab lookup.",
                    in_library=True,
                    episode_files=0,
                    episode_count=8,
                    base=base,
                )
                created["qualityProfileId"] = incoming.get("qualityProfileId") or 1
                created["rootFolderPath"] = incoming.get("rootFolderPath") or "/tv"
                LAB.series[series_id] = created
                LAB.episodes[series_id] = [
                    episode_record(
                        8000 + series_id,
                        series_id,
                        1,
                        1,
                        "Pilot",
                        has_file=False,
                        airs=NOW + timedelta(days=2),
                    )
                ]
                self._json(self._with_base(created, base, "series"))
                return
            if method == "PUT" and path == "/api/v3/series/editor":
                incoming = self._json_body(body)
                for series_id in incoming.get("seriesIds") or []:
                    item = LAB.series.get(int(series_id))
                    if item is None:
                        continue
                    for key in ("monitored", "qualityProfileId", "rootFolderPath", "seriesType", "tags"):
                        if key in incoming:
                            item[key] = incoming[key]
                self._json({})
                return
            if method == "DELETE" and re.fullmatch(r"/api/v3/series/\d+", path):
                series_id = int(path.rsplit("/", 1)[-1])
                LAB.series.pop(series_id, None)
                LAB.episodes.pop(series_id, None)
                self._json({})
                return
            if method == "GET" and path == "/api/v3/episode":
                series_id = int((query.get("seriesId") or ["0"])[0])
                self._json(LAB.episodes.get(series_id, []))
                return
            if method == "GET" and re.fullmatch(r"/api/v3/episode/\d+", path):
                episode_id = int(path.rsplit("/", 1)[-1])
                for episodes in LAB.episodes.values():
                    for episode in episodes:
                        if episode["id"] == episode_id:
                            self._json(episode)
                            return
                self._json({"message": "Not found"}, 404)
                return
            if method == "PUT" and path == "/api/v3/episode/monitor":
                incoming = self._json_body(body)
                wanted = set(incoming.get("episodeIds") or [])
                for episodes in LAB.episodes.values():
                    for episode in episodes:
                        if episode["id"] in wanted:
                            episode["monitored"] = bool(incoming.get("monitored"))
                self._json({})
                return
            if method == "GET" and path == "/api/v3/release":
                series_id = int((query.get("seriesId") or ["0"])[0])
                self._json(LAB.series_releases(series_id))
                return
            if method == "POST" and path == "/api/v3/release":
                incoming = self._json_body(body)
                LAB.grab(str(incoming.get("guid") or ""), movies=False)
                self._json({})
                return
            if method == "GET" and path == "/api/v3/calendar":
                upcoming = []
                for series_id, episodes in LAB.episodes.items():
                    series = LAB.series.get(series_id)
                    for episode in episodes:
                        air = episode.get("airDateUtc")
                        if air and air >= iso(NOW - timedelta(days=2)):
                            copied = json.loads(json.dumps(episode))
                            if series is not None:
                                copied["series"] = self._with_base(series, base, "series")
                            upcoming.append(copied)
                self._json(upcoming)
                return
            if method == "PUT" and re.fullmatch(r"/api/v3/series/\d+", path):
                series_id = int(path.rsplit("/", 1)[-1])
                item = LAB.series.get(series_id)
                if item is None:
                    self._json({"message": "Not found"}, 404)
                    return
                incoming = self._json_body(body)
                if "monitored" in incoming:
                    item["monitored"] = incoming["monitored"]
                if isinstance(incoming.get("seasons"), list):
                    item["seasons"] = incoming["seasons"]
                self._json(self._with_base(item, base, "series"))
                return
            if method == "GET" and path == "/api/v3/queue":
                records = []
                for item in LAB.series_queue:
                    copied = json.loads(json.dumps(item))
                    series = LAB.series.get(copied.get("seriesId") or 0)
                    if series:
                        copied["series"] = self._with_base(series, base, "series")
                    records.append(copied)
                self._json(self._page(records, query))
                return
            if method == "DELETE" and re.fullmatch(r"/api/v3/queue/\d+", path):
                item_id = int(path.rsplit("/", 1)[-1])
                LAB.series_queue = [
                    item for item in LAB.series_queue if item["id"] != item_id
                ]
                self._json({})
                return
            if method == "GET" and path == "/api/v3/history":
                records = []
                for event in LAB.series_history:
                    copied = json.loads(json.dumps(event))
                    series = LAB.series.get(copied.get("seriesId") or 0)
                    if series and (query.get("includeSeries") or ["false"])[0] == "true":
                        copied["series"] = self._with_base(series, base, "series")
                    records.append(copied)
                self._json(self._page(records, query))
                return
            if method == "GET" and path == "/api/v3/history/series":
                series_id = int((query.get("seriesId") or ["0"])[0])
                self._json(
                    [
                        event
                        for event in LAB.series_history
                        if event.get("seriesId") == series_id
                    ]
                )
                return
            if method == "GET" and path == "/api/v3/episodefile":
                series_id = int((query.get("seriesId") or ["0"])[0])
                files = [
                    episode["episodeFile"]
                    for episode in LAB.episodes.get(series_id, [])
                    if episode.get("episodeFile")
                ]
                self._json(files)
                return
            if method == "GET" and re.fullmatch(r"/api/v3/episodefile/\d+", path):
                file_id = int(path.rsplit("/", 1)[-1])
                for episodes in LAB.episodes.values():
                    for episode in episodes:
                        current = episode.get("episodeFile") or {}
                        if current.get("id") == file_id:
                            self._json(current)
                            return
                self._json({"message": "Not found"}, 404)
                return
            if method == "DELETE" and re.fullmatch(r"/api/v3/episodefile/\d+", path):
                self._delete_episode_files([int(path.rsplit("/", 1)[-1])])
                self._json({})
                return
            if method == "DELETE" and path == "/api/v3/episodefile/bulk":
                incoming = self._json_body(body)
                self._delete_episode_files(incoming.get("episodeFileIds") or [])
                self._json({})
                return
            if method == "GET" and path == "/api/v3/extrafile":
                series_id = int((query.get("seriesId") or ["0"])[0])
                self._json(
                    [
                        {
                            "id": 1,
                            "seriesId": series_id,
                            "relativePath": "Season 01/subs/english.srt",
                            "extension": ".srt",
                            "type": "subtitle",
                        }
                    ]
                )
                return
            if method == "GET" and path == "/api/v3/manualimport":
                series = LAB.series.get(1)
                episode = (LAB.episodes.get(1) or [None])[-1]
                self._json(
                    [
                        {
                            "id": 1,
                            "name": "Severance S01E09.mkv",
                            "path": "/downloads/Severance S01E09.mkv",
                            "relativePath": "Severance S01E09.mkv",
                            "size": 1_500_000_000,
                            "quality": HD,
                            "languages": [ENGLISH],
                            "downloadId": (query.get("downloadId") or ["8" * 40])[0],
                            "series": self._with_base(series, base, "series") if series else None,
                            "episodes": [episode] if episode else [],
                            "rejections": [],
                        }
                    ]
                )
                return
            if method == "POST" and path == "/api/v3/command":
                incoming = self._json_body(body)
                LAB.next_command_id += 1
                self._json(
                    {
                        "id": LAB.next_command_id,
                        "name": incoming.get("name"),
                        "status": "completed",
                    }
                )
                return
            if method == "POST" and path == "/api/v3/notification":
                incoming = self._json_body(body)
                incoming["id"] = len(LAB.notifications) + 1
                LAB.notifications.append(incoming)
                self._json(incoming)
                return
        self._json({"message": f"Unhandled {method} {path}"}, 404)

    def _delete_episode_files(self, file_ids: list) -> None:
        wanted = {int(file_id) for file_id in file_ids}
        for episodes in LAB.episodes.values():
            for episode in episodes:
                current = episode.get("episodeFile") or {}
                if current.get("id") in wanted:
                    episode["episodeFile"] = None
                    episode["hasFile"] = False
                    episode["episodeFileId"] = None

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
                    release_record(
                        "prowlarr-1",
                        f"{term} 2021 Bluray-1080p",
                        indexer="1337x",
                        indexer_id=1,
                    ),
                    release_record(
                        "prowlarr-2",
                        f"{term} 2021 Remux-2160p",
                        indexer="TorrentDay",
                        indexer_id=2,
                    ),
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
        if path == "/api/v2/auth/login" and method == "POST":
            fields = self._form(body)
            username = (fields.get("username") or [""])[0]
            password = (fields.get("password") or [""])[0]
            if username == QBIT_USER and password == QBIT_PASSWORD:
                self._text(
                    "Ok.",
                    extra={"Set-Cookie": f"SID={QBIT_SID}; Path=/; HttpOnly"},
                )
                return
            self._text("Fails.", 403)
            return
        if path == "/api/v2/app/version" and not self._qbit_authorized():
            # Connection probes accept any HTTP response, including 403.
            if method == "GET" and "Authorization" not in self.headers and "Cookie" not in self.headers:
                self._text("Forbidden", 403)
                return
        if not self._qbit_authorized():
            self._text("Forbidden", 403)
            return
        if method == "GET" and path == "/api/v2/app/version":
            self._text("v5.1.2")
            return
        if method == "GET" and path == "/api/v2/app/webapiVersion":
            self._text("2.11.2")
            return
        with LOCK:
            if method == "GET" and path == "/api/v2/torrents/info":
                wanted = (query.get("filter") or ["all"])[0]
                torrents = LAB.torrents
                if wanted == "downloading":
                    torrents = [item for item in torrents if item["state"] == "downloading"]
                elif wanted in ("seeding", "completed"):
                    torrents = [item for item in torrents if item["progress"] >= 1]
                elif wanted == "paused":
                    torrents = [
                        item
                        for item in torrents
                        if item["state"] in ("pausedDL", "pausedUP", "stoppedDL", "stoppedUP")
                    ]
                elif wanted in ("error", "errored"):
                    torrents = [item for item in torrents if item["state"] == "error"]
                self._json(torrents)
                return
            if method == "GET" and path == "/api/v2/torrents/files":
                infohash = (query.get("hash") or [""])[0]
                torrent = next((item for item in LAB.torrents if item["hash"] == infohash), None)
                name = torrent["name"] if torrent else "file"
                self._json(
                    [
                        {
                            "name": f"{name}/{name}.mkv",
                            "size": 5_800_000_000,
                            "progress": torrent["progress"] if torrent else 0,
                            "priority": 1,
                            "is_seed": bool(torrent and torrent["progress"] >= 1),
                            "availability": 1,
                        }
                    ]
                )
                return
            if method == "GET" and path == "/api/v2/sync/torrentPeers":
                self._json(
                    {
                        "peers": {
                            "203.0.113.10:51413": {
                                "port": 51413,
                                "connection": "BT",
                                "country_code": "BR",
                                "country": "Brazil",
                                "client": "qBittorrent",
                                "client_version": "5.1.2",
                                "flags": "D",
                                "progress": 0.8,
                                "dl_speed": 1_200_000,
                                "up_speed": 40_000,
                                "downloaded": 2_000_000_000,
                                "uploaded": 30_000_000,
                                "relevance": 1,
                            }
                        }
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
            if method == "POST" and path in (
                "/api/v2/torrents/pause",
                "/api/v2/torrents/stop",
                "/api/v2/torrents/resume",
                "/api/v2/torrents/start",
                "/api/v2/torrents/recheck",
                "/api/v2/torrents/delete",
                "/api/v2/torrents/setLocation",
                "/api/v2/torrents/filePrio",
                "/api/v2/torrents/add",
            ):
                fields = self._form(body)
                hashes = (fields.get("hashes") or [""])[0].split("|")
                hashes = [item for item in hashes if item]
                if path in ("/api/v2/torrents/pause", "/api/v2/torrents/stop"):
                    for torrent in LAB.torrents:
                        if torrent["hash"] in hashes:
                            torrent["state"] = (
                                "pausedUP" if torrent["progress"] >= 1 else "pausedDL"
                            )
                            torrent["dlspeed"] = 0
                elif path in ("/api/v2/torrents/resume", "/api/v2/torrents/start"):
                    for torrent in LAB.torrents:
                        if torrent["hash"] in hashes:
                            torrent["state"] = (
                                "uploading" if torrent["progress"] >= 1 else "downloading"
                            )
                elif path == "/api/v2/torrents/recheck":
                    for torrent in LAB.torrents:
                        if torrent["hash"] in hashes:
                            torrent["state"] = "checkingDL"
                elif path == "/api/v2/torrents/delete":
                    LAB.torrents = [
                        torrent for torrent in LAB.torrents if torrent["hash"] not in hashes
                    ]
                elif path == "/api/v2/torrents/setLocation":
                    location = (fields.get("location") or [""])[0]
                    for torrent in LAB.torrents:
                        if torrent["hash"] in hashes:
                            torrent["save_path"] = location
                elif path == "/api/v2/torrents/add":
                    urls = (fields.get("urls") or [""])[0]
                    name = urls or "Added torrent"
                    infohash = (str(abs(hash(name))) + "0" * 40)[:40]
                    LAB.torrents.insert(
                        0,
                        LAB._torrent(
                            infohash,
                            name[-80:],
                            state="downloading",
                            progress=0,
                            category=(fields.get("category") or ["radarr"])[0],
                        ),
                    )
                self._text("Ok.")
                return
        self._text("Not found", 404)


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
