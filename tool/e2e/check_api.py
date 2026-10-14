#!/usr/bin/env python3
"""Check the lab's HTTP contracts and cross-service side effects.

Requires fresh fixtures and mutates the disposable lab. This suite does not
launch Arrmate or verify UI actions. It uses only the standard library.
"""

import http.client
import json
import time
import unittest
from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode, urlsplit

PORTS = {"radarr": 7878, "sonarr": 8989, "prowlarr": 9696, "qbit": 8080, "jellyfin": 8096}

# The MediaBrowser authorization header the app sends to `/Users/AuthenticateByName`.
JELLYFIN_BROWSER_AUTH = {
    "Authorization": 'MediaBrowser Client="Arrmate", Device="Arrmate", '
    'DeviceId="arrmate-api-check", Version="1.0"'
}

# Authenticated calls use the Jellyfin 12 scheme: the MediaBrowser
# Authorization header carrying Token, mirroring JellyfinService.
JELLYFIN_TOKEN_AUTH = {
    "Authorization": JELLYFIN_BROWSER_AUTH["Authorization"] + ', Token="arrmate-jellyfin"'
}


def request(role, path, *, method="GET", data=None, form=None, auth=True,
            headers=None, status=200, query=None):
    """Send a bounded request to the local lab and check the HTTP status."""
    if query:
        path += "?" + urlencode(query, doseq=True)
    outgoing = {}
    if auth:
        outgoing = ({"Authorization": "Bearer arrmate-qbit"} if role == "qbit"
                    else dict(JELLYFIN_TOKEN_AUTH) if role == "jellyfin"
                    else {"X-Api-Key": f"arrmate-{role}"})
    outgoing.update(headers or {})
    body = None
    if data is not None:
        body = json.dumps(data)
        outgoing["Content-Type"] = "application/json"
    elif form is not None:
        body = urlencode(form)
        outgoing["Content-Type"] = "application/x-www-form-urlencoded"
    connection = http.client.HTTPConnection("127.0.0.1", PORTS[role], timeout=5)
    try:
        connection.request(method, path, body, outgoing)
        response = connection.getresponse()
        raw = response.read()
        if response.status != status:
            raise AssertionError(f"{role} {method} {path}: expected HTTP {status}, "
                                 f"got {response.status}: {raw[:200]!r}")
        value = (json.loads(raw) if raw and "application/json" in
                 response.getheader("Content-Type", "") else raw)
        return value, dict(response.getheaders())
    finally:
        connection.close()


def api(role, path, **kwargs):
    """Return the decoded body of a checked HTTP response."""
    return request(role, path, **kwargs)[0]


def _jellyfin_session(token):
    """Wrap a session token the way the app sends it (MediaBrowser Token)."""
    return {"Authorization": JELLYFIN_BROWSER_AUTH["Authorization"] + f', Token="{token}"'}


def jellyfin_login(username, password, *, status=200):
    """Authenticate a lab Jellyfin user the way the app does."""
    return request("jellyfin", "/Users/AuthenticateByName", method="POST",
                   auth=False, data={"Username": username, "Pw": password},
                   headers=JELLYFIN_BROWSER_AUTH, status=status)[0]


class MediaLabChecks(unittest.TestCase):
    """Ordered scenarios against fresh fixtures, including persisted effects."""

    @classmethod
    def setUpClass(cls):
        deadline = time.monotonic() + 30
        while True:
            try:
                for role in PORTS:
                    api(role, "/api/v2/app/version" if role == "qbit" else
                        "/System/Info/Public" if role == "jellyfin" else "/ping",
                        auth=role != "jellyfin")
                break
            except (OSError, AssertionError, http.client.HTTPException):
                if time.monotonic() >= deadline:
                    raise
                time.sleep(0.5)
        movies = api("radarr", "/api/v3/movie")
        series = api("sonarr", "/api/v3/series")
        torrents = api("qbit", "/api/v2/torrents/info")
        catalog = api("jellyfin", "/Items", query={"Recursive": "true",
                                                   "IncludeItemTypes": "Movie"})["Items"]
        if ({item["id"] for item in movies} != {1, 2, 3, 4} or
                {item["id"] for item in series} != {1, 2} or len(torrents) != 9 or
                next(item for item in movies if item["id"] == 3)["hasFile"] or
                {item["Name"] for item in catalog} != {"Dune", "The Matrix",
                                                       "The Matrix Reloaded"}):
            raise AssertionError("Restart the media lab before running these destructive checks.")

    def test_01_authentication_and_cors(self):
        for role in ("radarr", "sonarr", "prowlarr"):
            path = "/api/v3/system/status" if role != "prowlarr" else "/api/v1/search"
            api(role, path, auth=False, status=401)
            api(role, path, headers={"X-Api-Key": "wrong"}, status=401)
        api("qbit", "/api/v2/torrents/info", auth=False, status=403)
        failed = api("qbit", "/api/v2/auth/login", method="POST", auth=False,
                     form={"username": "admin", "password": "wrong"})
        self.assertEqual(failed, b"Fails.")
        body, headers = request("qbit", "/api/v2/auth/login", method="POST", auth=False,
                                form={"username": "admin", "password": "adminarr"})
        self.assertEqual(body, b"Ok.")
        cookie = headers["Set-Cookie"].split(";")[0]
        self.assertEqual(len(api("qbit", "/api/v2/torrents/info", auth=False,
                                 headers={"Cookie": cookie})), 9)
        _, headers = request("radarr", "/api/v3/movie", method="OPTIONS", auth=False, status=204)
        self.assertEqual(headers["Access-Control-Allow-Origin"], "*")
        self.assertIn("X-Api-Key", headers["Access-Control-Allow-Headers"])

    def test_02_libraries_lookup_and_covers(self):
        self.assertEqual({item["title"] for item in api("radarr", "/api/v3/movie")},
                         {"Dune", "The Matrix", "Arrival", "Oppenheimer"})
        self.assertEqual({item["title"] for item in api("sonarr", "/api/v3/series")},
                         {"Severance", "The Bear"})
        for role, kind, title, identifier in (("radarr", "movie", "Inception", "tmdb:27205"),
                                               ("sonarr", "series", "Shogun", "tvdb:417742")):
            for term in (title, identifier):
                results = api(role, f"/api/v3/{kind}/lookup", query={"term": term})
                self.assertEqual(len(results), 1)
                self.assertEqual(results[0]["id"], 0)
                self.assertEqual(results[0]["title"], title)
            image = results[0]["images"][0]["remoteUrl"]
            self.assertTrue(api(role, urlsplit(image).path).startswith(b"\x89PNG"))

    def test_03_system_profiles_folders_health_and_logs(self):
        for role, version, folder in (("radarr", "5.18.4", "/movies"),
                                      ("sonarr", "4.0.14", "/tv")):
            self.assertTrue(api(role, "/api/v3/system/status")["version"].startswith(version))
            self.assertEqual({item["name"] for item in api(role, "/api/v3/qualityprofile")},
                             {"HD-1080p", "Ultra-HD"})
            self.assertIn(folder, [item["path"] for item in api(role, "/api/v3/rootfolder")])
            self.assertEqual(len(api(role, "/api/v3/diskspace")), 3)
            self.assertEqual(len(api(role, "/api/v3/health")), 2)
            self.assertEqual(len(api(role, "/api/v3/tag")), 2)
            self.assertEqual(api(role, "/api/v3/downloadclient")[0]["implementation"], "QBittorrent")
            errors = api(role, "/api/v3/log", query={"level": "error"})["records"]
            self.assertTrue(errors)
            self.assertTrue(all(item["level"] == "error" for item in errors))

    def test_04_calendar_ranges_and_specials(self):
        today = datetime.now(timezone.utc)
        query = {"start": today.isoformat(), "end": (today + timedelta(days=8)).isoformat(),
                 "includeSeries": "true", "unmonitored": "true"}
        events = api("sonarr", "/api/v3/calendar", query=query)
        self.assertEqual({(item["seasonNumber"], item["episodeNumber"]) for item in events},
                         {(0, 1), (2, 1)})
        self.assertTrue(all(item["series"]["title"] == "Severance" for item in events))
        query["unmonitored"] = "false"
        self.assertEqual(len(api("sonarr", "/api/v3/calendar", query=query)), 1)
        query.update(start=(today + timedelta(days=29)).isoformat(),
                     end=(today + timedelta(days=31)).isoformat())
        self.assertEqual([item["title"] for item in api("radarr", "/api/v3/calendar", query=query)],
                         ["Oppenheimer"])
        query.update(start=(today + timedelta(days=200)).isoformat(),
                     end=(today + timedelta(days=201)).isoformat())
        for role in ("radarr", "sonarr"):
            self.assertEqual(api(role, "/api/v3/calendar", query=query), [])

    def test_05_history_filters_and_pagination(self):
        for role in ("radarr", "sonarr"):
            for code, event in ((1, "grabbed"), (3, "downloadFolderImported")):
                query = {"eventType": code, "pageSize": 1}
                page = api(role, "/api/v3/history", query=query)
                self.assertEqual(len(page["records"]), 1)
                self.assertGreater(page["totalRecords"], 1)
                self.assertTrue(all(item["eventType"] == event for item in page["records"]))
                next_page = api(role, "/api/v3/history", query={**query, "page": 2})
                self.assertTrue({item["id"] for item in page["records"]}.isdisjoint(
                    {item["id"] for item in next_page["records"]}))

    def test_06_torrent_filters_files_peers_and_badge_inputs(self):
        downloading = api("qbit", "/api/v2/torrents/info", query={"filter": "downloading"})
        self.assertEqual({item["hash"] for item in downloading}, {"c" * 40, "8" * 40, "7" * 40})
        seeding = api("qbit", "/api/v2/torrents/info", query={"filter": "seeding"})
        self.assertEqual(len(seeding), 4)
        matrix = [item for item in seeding if "Matrix" in item["name"]]
        self.assertEqual(len(matrix), 2)
        self.assertEqual(matrix[0]["name"], matrix[1]["name"])
        history = api("radarr", "/api/v3/history/movie", query={"movieId": 2})
        self.assertEqual({item["downloadId"] for item in history}, {"A" * 40})
        self.assertEqual(len(api("qbit", "/api/v2/torrents/files", query={"hash": "a" * 40})), 3)
        self.assertEqual(len(api("qbit", "/api/v2/sync/torrentPeers", query={"hash": "a" * 40})["peers"]), 1)
        self.assertEqual(api("qbit", "/api/v2/sync/torrentPeers", query={"hash": "d" * 40})["peers"], {})
        self.assertEqual(set(api("qbit", "/api/v2/torrents/categories")), {"radarr", "sonarr", "cross-seed"})
        self.assertIn("arrmate", api("qbit", "/api/v2/torrents/tags"))

    def test_07_add_and_edit_movie_and_series(self):
        for role, kind, term, folder in (("radarr", "movie", "inception", "/movies-4k"),
                                         ("sonarr", "series", "shogun", "/tv-anime")):
            lookup = api(role, f"/api/v3/{kind}/lookup", query={"term": term})[0]
            created = api(role, f"/api/v3/{kind}", method="POST", status=201,
                          data={**lookup, "rootFolderPath": folder, "qualityProfileId": 2,
                                "monitored": True, "addOptions": {"monitor": "all"}})
            setattr(type(self), f"{kind}_id", created["id"])
            self.assertGreater(created["id"], 0)
            api(role, f"/api/v3/{kind}", method="POST", data=lookup, status=400)
            api(role, f"/api/v3/{kind}/editor", method="PUT", status=202,
                data={f"{kind}Ids": [created["id"]], "qualityProfileId": 1,
                      "tags": [1, 2], "applyTags": "replace", "monitored": True})
            saved = api(role, f"/api/v3/{kind}/{created['id']}")
            self.assertEqual(saved["qualityProfileId"], 1)
            self.assertEqual(saved["tags"], [1, 2])
            self.assertEqual(saved["rootFolderPath"], folder)
        episodes = api("sonarr", "/api/v3/episode", query={"seriesId": self.series_id})
        self.assertEqual(len(episodes), 10)
        type(self).episode_id = episodes[0]["id"]

    def test_08_season_and_episode_monitoring(self):
        series = api("sonarr", "/api/v3/series/1")
        for season in series["seasons"]:
            if season["seasonNumber"] == 2:
                season["monitored"] = False
        api("sonarr", "/api/v3/series/1", method="PUT", data=series, status=202)
        episodes = api("sonarr", "/api/v3/episode", query={"seriesId": 1, "seasonNumber": 2})
        self.assertTrue(episodes)
        self.assertTrue(all(not episode["monitored"] for episode in episodes))
        api("sonarr", "/api/v3/episode/monitor", method="PUT", status=202,
            data={"episodeIds": [11], "monitored": False})
        self.assertFalse(api("sonarr", "/api/v3/episode/11")["monitored"])

    def test_09_grab_creates_torrent_queue_and_history_in_both_services(self):
        for role, query, identity in (("radarr", {"movieId": self.movie_id}, self.movie_id),
                                      ("sonarr", {"episodeId": self.episode_id}, self.episode_id)):
            releases = api(role, "/api/v3/release", query=query)
            self.assertTrue(any(item["rejected"] for item in releases))
            release = next(item for item in releases if not item["rejected"] and "1080" in item["title"])
            before = {item["hash"] for item in api("qbit", "/api/v2/torrents/info")}
            api(role, "/api/v3/release", method="POST",
                data={"guid": release["guid"], "indexerId": release["indexerId"]})
            added = [item for item in api("qbit", "/api/v2/torrents/info") if item["hash"] not in before]
            self.assertEqual(len(added), 1, "A grab must create a new torrent, not merely acknowledge the POST")
            torrent = added[0]
            self.assertEqual(torrent["category"], role)
            self.assertEqual(torrent["name"], release["title"])
            setattr(type(self), f"{role}_grab_hash", torrent["hash"])
            queue = api(role, "/api/v3/queue")["records"]
            item = next(item for item in queue if item["downloadId"] == torrent["hash"].upper())
            self.assertEqual(item["movieId" if role == "radarr" else "episodeId"], identity)
            history = api(role, "/api/v3/history", query={"eventType": 1})["records"]
            self.assertTrue(any(item["downloadId"] == torrent["hash"].upper() for item in history))
        self.assertTrue(api("prowlarr", "/api/v1/search", query={"query": "Dune"}))

    def test_10_torrent_stop_start_priority_location_and_recheck(self):
        infohash = "c" * 40
        api("qbit", "/api/v2/torrents/stop", method="POST", form={"hashes": infohash})
        torrent = api("qbit", "/api/v2/torrents/info", query={"hashes": infohash})[0]
        self.assertEqual(torrent["state"], "stoppedDL")
        queue = api("radarr", "/api/v3/queue")["records"]
        self.assertEqual(next(item for item in queue if item["movieId"] == 1)["status"].lower(), "paused")
        api("qbit", "/api/v2/torrents/start", method="POST", form={"hashes": infohash})
        self.assertEqual(api("qbit", "/api/v2/torrents/info", query={"hashes": infohash})[0]["state"], "downloading")
        api("qbit", "/api/v2/torrents/filePrio", method="POST",
            form={"hash": infohash, "id": "1", "priority": 0})
        self.assertEqual(api("qbit", "/api/v2/torrents/files", query={"hash": infohash})[1]["priority"], 0)
        api("qbit", "/api/v2/torrents/setLocation", method="POST", form={"hashes": infohash, "location": "/downloads/moved"})
        self.assertEqual(api("qbit", "/api/v2/torrents/info", query={"hashes": infohash})[0]["save_path"], "/downloads/moved")
        api("qbit", "/api/v2/torrents/recheck", method="POST", form={"hashes": infohash})
        self.assertEqual(api("qbit", "/api/v2/torrents/info", query={"hashes": infohash})[0]["state"], "checkingDL")
        self.wait_for(lambda: api("qbit", "/api/v2/torrents/info", query={"hashes": infohash})[0]["state"] == "downloading", 8)

    def test_11_manual_import_writes_file_and_removes_queue(self):
        candidates = api("radarr", "/api/v3/manualimport", query={"downloadId": "D" * 40})
        self.assertTrue(any(item["rejections"] for item in candidates))
        video = next(item for item in candidates if not item["rejections"])
        self.assertFalse(api("radarr", "/api/v3/movie/3")["hasFile"])
        api("radarr", "/api/v3/command", method="POST", status=201,
            data={"name": "ManualImport", "files": [{"movieId": 3, "path": video["path"], "downloadId": "D" * 40}]})
        self.assertTrue(api("radarr", "/api/v3/movie/3")["hasFile"])
        self.assertFalse(any(item["downloadId"] == "D" * 40 for item in api("radarr", "/api/v3/queue")["records"]))
        imported = api("radarr", "/api/v3/history/movie", query={"movieId": 3, "eventType": 3})
        self.assertTrue(any(item["downloadId"] == "D" * 40 for item in imported))

    def test_12_queue_removal_and_blocklist(self):
        item = next(item for item in api("sonarr", "/api/v3/queue")["records"] if item["episodeId"] == 15)
        api("sonarr", f"/api/v3/queue/{item['id']}", method="DELETE",
            query={"removeFromClient": "true", "blocklist": "true", "skipRedownload": "true"})
        self.assertEqual(api("qbit", "/api/v2/torrents/info", query={"hashes": "7" * 40}), [])
        self.assertFalse(any(row["id"] == item["id"] for row in api("sonarr", "/api/v3/queue")["records"]))
        self.assertTrue(api("sonarr", "/api/v3/blocklist")["records"])
        events = api("sonarr", "/api/v3/history", query={"eventType": 4})["records"]
        self.assertTrue(any(row["downloadId"] == "7" * 40 for row in events))

    def test_13_notification_configuration_round_trip(self):
        for role in ("radarr", "sonarr"):
            schema = api(role, "/api/v3/notification/schema")
            self.assertEqual(schema[0]["implementation"], "Ntfy")
            created = api(role, "/api/v3/notification", method="POST", status=201,
                          data={**schema[0], "name": "Arrmate API check", "onGrab": True})
            api(role, f"/api/v3/notification/{created['id']}", method="PUT", status=202,
                data={**created, "onGrab": False})
            saved = api(role, "/api/v3/notification")
            self.assertEqual(len(saved), 1)
            self.assertFalse(saved[0]["onGrab"])
            api(role, f"/api/v3/notification/{created['id']}", method="DELETE")
            self.assertEqual(api(role, "/api/v3/notification"), [])

    def test_14_add_paused_torrent_and_delete(self):
        infohash = "0123456789abcdef0123456789abcdef01234567"
        api("qbit", "/api/v2/torrents/add", method="POST",
            form={"urls": f"magnet:?xt=urn:btih:{infohash}&dn=API+Check", "stopped": "true",
                  "category": "radarr", "tags": "arrmate", "savepath": "/downloads/api-check"})
        torrent = api("qbit", "/api/v2/torrents/info", query={"hashes": infohash})[0]
        self.assertEqual(torrent["state"], "stoppedDL")
        self.assertEqual(torrent["save_path"], "/downloads/api-check")
        api("qbit", "/api/v2/torrents/delete", method="POST", form={"hashes": infohash, "deleteFiles": "false"})
        self.assertEqual(api("qbit", "/api/v2/torrents/info", query={"hashes": infohash}), [])

    def test_15_auto_import_completes_both_grabs(self):
        self.wait_for(lambda: api("radarr", f"/api/v3/movie/{self.movie_id}")["hasFile"] and
                      api("sonarr", f"/api/v3/episode/{self.episode_id}")["hasFile"], 75)
        for role in ("radarr", "sonarr"):
            infohash = getattr(self, f"{role}_grab_hash")
            self.assertEqual(api("qbit", "/api/v2/torrents/info", query={"hashes": infohash})[0]["state"], "uploading")
            self.assertFalse(any(item["downloadId"] == infohash.upper() for item in api(role, "/api/v3/queue")["records"]))
            history = api(role, "/api/v3/history", query={"eventType": 3})["records"]
            self.assertTrue(any(item["downloadId"] == infohash.upper() for item in history))

    def test_16_delete_files_and_catalog_clears_history(self):
        movie = api("radarr", f"/api/v3/movie/{self.movie_id}")
        api("radarr", f"/api/v3/moviefile/{movie['movieFile']['id']}", method="DELETE")
        self.assertFalse(api("radarr", f"/api/v3/movie/{self.movie_id}")["hasFile"])
        self.assertTrue(api("radarr", "/api/v3/history/movie", query={"movieId": self.movie_id, "eventType": 6}))
        episode = api("sonarr", f"/api/v3/episode/{self.episode_id}")
        api("sonarr", f"/api/v3/episodefile/{episode['episodeFile']['id']}", method="DELETE")
        self.assertFalse(api("sonarr", f"/api/v3/episode/{self.episode_id}")["hasFile"])
        for role, kind, item_id in (("radarr", "movie", self.movie_id), ("sonarr", "series", self.series_id)):
            api(role, f"/api/v3/{kind}/{item_id}", method="DELETE", query={"deleteFiles": "true"})
            api(role, f"/api/v3/{kind}/{item_id}", status=404)
            self.assertEqual(api(role, "/api/v3/history", query={f"{kind}Id": item_id})["records"], [])
            self.assertEqual(len(api("qbit", "/api/v2/torrents/info", query={"hashes": getattr(self, f"{role}_grab_hash")})), 1)

    def test_17_jellyfin_public_info_auth_and_keys(self):
        public = api("jellyfin", "/System/Info/Public", auth=False)
        self.assertEqual(public["ServerName"], "Arrmate Lab Jellyfin")
        self.assertTrue(public["Version"].startswith("10.10.6"))
        api("jellyfin", "/System/Info", auth=False, status=401)
        jellyfin_login("arrmate", "wrong-password", status=401)
        jellyfin_login("nobody", "arrmate-jellyfin", status=401)
        admin = jellyfin_login("arrmate", "arrmate-jellyfin")
        self.assertTrue(admin["User"]["Policy"]["IsAdministrator"])
        type(self).jellyfin_admin = admin["AccessToken"]
        guest = jellyfin_login("guest", "guest-arrmate")
        self.assertFalse(guest["User"]["Policy"]["IsAdministrator"])
        type(self).jellyfin_guest = guest["AccessToken"]
        keys = api("jellyfin", "/Auth/Keys", headers=_jellyfin_session(self.jellyfin_admin))
        self.assertEqual([item["AppName"] for item in keys["Items"]], ["Jellyfin Media Player"])
        api("jellyfin", "/Auth/Keys", method="POST", query={"app": "Arrmate"},
            headers=_jellyfin_session(self.jellyfin_admin), status=204)
        api("jellyfin", "/Auth/Keys", method="POST", query={"app": "Arrmate"},
            headers=_jellyfin_session(self.jellyfin_admin), status=204)
        keys = api("jellyfin", "/Auth/Keys", headers=_jellyfin_session(self.jellyfin_admin))
        self.assertEqual([item["AppName"] for item in keys["Items"]],
                         ["Jellyfin Media Player", "Arrmate"])
        minted = next(item for item in keys["Items"] if item["AppName"] == "Arrmate")
        api("jellyfin", "/Auth/Keys", headers=_jellyfin_session(self.jellyfin_guest), status=403)
        # The minted key is a working credential, and so is the fixture API key.
        for token in (minted["AccessToken"], "arrmate-jellyfin"):
            self.assertTrue(api("jellyfin", "/System/Info",
                                headers=_jellyfin_session(token))["Version"].startswith("10.10.6"))

    def test_18_jellyfin_catalog_search_and_decoys(self):
        movies = api("jellyfin", "/Items", query={"Recursive": "true",
                                                  "IncludeItemTypes": "Movie"})["Items"]
        self.assertEqual({item["Name"] for item in movies},
                         {"Dune", "The Matrix", "The Matrix Reloaded"})
        hits = api("jellyfin", "/Items", query={
            "Recursive": "true", "IncludeItemTypes": "Movie,Episode,Video",
            "Fields": "Path,MediaSources,ProviderIds", "SearchTerm": "matrix",
            "Limit": "100"})["Items"]
        self.assertEqual({item["Name"] for item in hits}, {"The Matrix", "The Matrix Reloaded"})
        dune = next(item for item in api("jellyfin", "/Items", query={
            "Recursive": "true", "IncludeItemTypes": "Movie",
            "SearchTerm": "Dune", "years": "2021"})["Items"])
        self.assertEqual(dune["Path"], api("radarr", "/api/v3/movie/1")["movieFile"]["path"])
        self.assertEqual(dune["ProviderIds"], {"Tmdb": "438631", "Imdb": "tt1160419"})
        streams = dune["MediaSources"][0]["MediaStreams"]
        audio = [stream for stream in streams if stream["Type"] == "Audio"]
        self.assertEqual({(stream["Language"], stream["IsDefault"]) for stream in audio},
                         {("eng", True), ("por", False)})
        subtitles = [stream for stream in streams if stream["Type"] == "Subtitle"]
        self.assertEqual(len(subtitles), 2)
        self.assertEqual([stream["Codec"] for stream in subtitles], ["ass", "subrip"])
        self.assertTrue(next(stream for stream in subtitles if stream["IsExternal"])["IsExternal"])
        self.assertFalse(any("DeliveryUrl" in stream for stream in subtitles))
        matrix = api("jellyfin", "/Items", query={
            "Recursive": "true", "IncludeItemTypes": "Movie",
            "SearchTerm": "The Matrix", "years": "1999"})["Items"]
        self.assertEqual([item["Name"] for item in matrix], ["The Matrix"])
        self.assertEqual(matrix[0]["ProviderIds"]["Tmdb"], "603")
        self.assertEqual(matrix[0]["UserData"]["PlaybackPositionTicks"], 600_000_000)

    def test_19_jellyfin_series_and_episodes(self):
        series = api("jellyfin", "/Items", query={"Recursive": "true",
                                                  "IncludeItemTypes": "Series",
                                                  "SearchTerm": "severance"})["Items"]
        self.assertEqual(len(series), 1)
        severance = series[0]
        self.assertEqual(severance["ProviderIds"]["Tvdb"], "371980")
        episodes = api("jellyfin", f"/Shows/{severance['Id']}/Episodes", query={
            "season": "1", "Fields": "Path,MediaSources,ProviderIds",
            "userId": "any-user"})["Items"]
        by_number = {item["IndexNumber"]: item for item in episodes}
        self.assertEqual(set(by_number), {1, 2, 3, 4, 5})
        fixture = api("sonarr", "/api/v3/episode/11")
        first = by_number[1]
        self.assertEqual(first["Path"], fixture["episodeFile"]["path"])
        self.assertEqual(first["SeriesName"], "Severance")
        self.assertEqual(first["ParentIndexNumber"], 1)
        self.assertEqual(first["ProviderIds"]["Tvdb"], str(fixture["tvdbId"]))
        self.assertTrue(first["MediaSources"][0]["MediaStreams"])
        sonarr_paths = {episode["episodeFile"]["path"]
                        for episode in api("sonarr", "/api/v3/episode", query={"seriesId": 1})
                        if episode.get("episodeFile")}
        self.assertNotIn(by_number[5]["Path"], sonarr_paths)
        season_two = api("jellyfin", f"/Shows/{severance['Id']}/Episodes",
                         query={"season": "2"})["Items"]
        self.assertEqual(season_two, [])
        api("jellyfin", "/Shows/unknown-series/Episodes", status=404)
        bear = api("jellyfin", "/Items", query={"Recursive": "true",
                                                "IncludeItemTypes": "Series",
                                                "SearchTerm": "the bear"})["Items"]
        self.assertEqual([item["Name"] for item in bear], ["The Bear"])
        bear_episodes = api("jellyfin", f"/Shows/{bear[0]['Id']}/Episodes",
                            query={"season": "1"})["Items"]
        self.assertEqual({item["IndexNumber"] for item in bear_episodes}, set(range(1, 9)))

    def test_20_jellyfin_playbackinfo_and_delivery_urls(self):
        dune = next(item for item in api("jellyfin", "/Items", query={
            "Recursive": "true", "IncludeItemTypes": "Movie",
            "SearchTerm": "Dune"})["Items"])
        profile = {"SubtitleProfiles": [
            {"Format": "vtt", "Method": "External"},
            {"Format": "srt", "Method": "External"},
            {"Format": "ass", "Method": "External"},
        ]}
        info = api("jellyfin", f"/Items/{dune['Id']}/PlaybackInfo", method="POST",
                   query={"userId": "any-user"},
                   data={"UserId": "any-user", "IsPlayback": True,
                         "AutoOpenLiveStream": True, "DeviceProfile": profile})
        source = info["MediaSources"][0]
        external = next(stream for stream in source["MediaStreams"]
                        if stream["Type"] == "Subtitle" and stream["IsExternal"])
        self.assertEqual(external["DeliveryUrl"],
                         f"/Videos/{dune['Id']}/{source['Id']}/Subtitles/{external['Index']}/0/Stream.vtt")
        embedded = next(stream for stream in source["MediaStreams"]
                        if stream["Type"] == "Subtitle" and not stream["IsExternal"])
        self.assertNotIn("DeliveryUrl", embedded)
        bare = api("jellyfin", f"/Items/{dune['Id']}/PlaybackInfo", method="POST",
                   data={"IsPlayback": True})["MediaSources"][0]["MediaStreams"]
        self.assertFalse(any("DeliveryUrl" in stream for stream in bare))
        api("jellyfin", "/Items/unknown-item/PlaybackInfo", method="POST",
            data={"IsPlayback": True}, status=404)

    def test_21_jellyfin_streams_hls_and_subtitles(self):
        dune = next(item for item in api("jellyfin", "/Items", query={
            "Recursive": "true", "IncludeItemTypes": "Movie",
            "SearchTerm": "Dune"})["Items"])
        source_id = dune["MediaSources"][0]["Id"]
        video, headers = request("jellyfin", f"/Videos/{dune['Id']}/stream", query={
            "static": "true", "MediaSourceId": source_id, "ApiKey": "arrmate-jellyfin"})
        self.assertEqual(headers["Content-Type"], "video/x-matroska")
        self.assertTrue(video.startswith(b"ARRMATE-LAB-VIDEO:"))
        api("jellyfin", f"/Videos/{dune['Id']}/stream", auth=False, status=401,
            query={"static": "true", "MediaSourceId": source_id})
        playlist, headers = request("jellyfin", f"/Videos/{dune['Id']}/master.m3u8",
                                    query={"MediaSourceId": source_id,
                                           "VideoBitrate": "4000000"})
        self.assertEqual(headers["Content-Type"], "application/vnd.apple.mpegurl")
        self.assertTrue(playlist.startswith(b"#EXTM3U"))
        subtitle = next(stream for stream in dune["MediaSources"][0]["MediaStreams"]
                        if stream["Type"] == "Subtitle" and stream["IsExternal"])
        payload, headers = request("jellyfin",
                                   f"/Videos/{dune['Id']}/{source_id}/Subtitles/{subtitle['Index']}/0/Stream.vtt",
                                   query={"ApiKey": "arrmate-jellyfin"})
        self.assertEqual(headers["Content-Type"], "text/vtt")
        self.assertTrue(payload.startswith(b"WEBVTT"))
        api("jellyfin", f"/Videos/{dune['Id']}/missing-source/Subtitles/4/0/Stream.vtt",
            status=404)

    def test_22_jellyfin_progress_sync_and_library_scan(self):
        query = {"Recursive": "true", "IncludeItemTypes": "Movie", "SearchTerm": "Dune"}
        dune = next(item for item in api("jellyfin", "/Items", query=query)["Items"])
        source_id = dune["MediaSources"][0]["Id"]
        for path, payload in (
            ("/Sessions/Playing/Start", {"ItemId": dune["Id"], "MediaSourceId": source_id}),
            ("/Sessions/Playing/Progress", {"ItemId": dune["Id"], "MediaSourceId": source_id,
                                            "PositionTicks": 450_000_000, "IsPaused": False}),
            ("/Sessions/Playing/Stopped", {"ItemId": dune["Id"], "MediaSourceId": source_id,
                                           "PositionTicks": 900_000_000}),
        ):
            api("jellyfin", path, method="POST",
                headers=_jellyfin_session(self.jellyfin_admin), data=payload, status=204)
        dune_after = next(item for item in api("jellyfin", "/Items", query=query)["Items"])
        self.assertEqual(dune_after["UserData"]["PlaybackPositionTicks"], 900_000_000)
        matrix = next(item for item in api("jellyfin", "/Items", query={
            "Recursive": "true", "IncludeItemTypes": "Movie",
            "SearchTerm": "The Matrix", "years": "1999"})["Items"])
        self.assertEqual(matrix["UserData"]["PlaybackPositionTicks"], 600_000_000)

        def catalog():
            return api("jellyfin", "/Items", query={
                "Recursive": "true", "IncludeItemTypes": "Movie,Episode,Video",
                "SearchTerm": "arrival"})["Items"]

        arrival_path = api("radarr", "/api/v3/movie/3")["movieFile"]["path"]
        self.assertFalse(any(item["Path"] == arrival_path for item in catalog()))
        updates = {"Updates": [{"Path": arrival_path, "UpdateType": "Created"}]}
        api("jellyfin", "/Library/Media/Updated", method="POST",
            headers=_jellyfin_session(self.jellyfin_guest), data=updates, status=403)
        self.assertFalse(any(item["Path"] == arrival_path for item in catalog()))
        api("jellyfin", "/Library/Media/Updated", method="POST",
            headers=_jellyfin_session(self.jellyfin_admin), data=updates, status=204)
        indexed = next(item for item in catalog() if item["Path"] == arrival_path)
        self.assertEqual(indexed["Type"], "Movie")
        self.assertEqual(indexed["Name"], "Arrival (2016) WEBDL-1080p")
        self.assertEqual(indexed["ProductionYear"], 2016)
        self.assertFalse(indexed["ProviderIds"])
        self.assertTrue(indexed["MediaSources"])

    def wait_for(self, condition, timeout):
        """Poll observable state with a deadline instead of sleeping a fixed minute."""
        deadline = time.monotonic() + timeout
        while not condition():
            if time.monotonic() >= deadline:
                self.fail(f"Expected state did not appear within {timeout}s")
            time.sleep(0.5)


if __name__ == "__main__":
    unittest.main(verbosity=2, failfast=True)
