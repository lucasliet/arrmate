# Arrmate knowledge base

## Overview
Arrmate is a mobile companion app for Radarr, Sonarr, and qBittorrent.

The app is built with Flutter and Riverpod. It focuses on media library management, download monitoring, notifications, and multi-instance support.

## Main navigation
The app uses a bottom navigation shell with five tabs:
- Movies
- Series
- Calendar
- Activity
- Settings

Notifications are shown on a separate full-screen route.

## Movies
The Movies area lets users browse, search, filter, sort, and manage movie libraries.

Movie details include metadata, files, history, release search, and edit actions.

## Series
The Series area provides the same type of management flow for TV series.

Series details include seasons, files, history, and edit actions.

## Calendar
The Calendar screen shows upcoming movie releases and series episodes.

## Activity
The Activity area covers queue monitoring, history, torrent import, and download tracking.

qBittorrent support includes live status, pause, resume, delete, recheck, and adding torrents through URLs or files.

## Settings
Settings is the central place for app configuration.

It currently contains:
- configured instances
- appearance settings
- home tab selection
- notification setup
- notification center
- logs
- health
- quality profiles
- about information

## Instances
Arrmate supports multiple instances at the same time.

Supported instance types include:
- Radarr
- Sonarr
- qBittorrent

Instances are persisted locally and can be validated, updated, and removed from Settings.

## Notifications
Arrmate integrates with ntfy.sh for push notifications.

Notification setup is managed inside Settings and can be automatically configured for new instances when enabled.

## Troubleshooting
If the app cannot connect to a configured instance, check:
- the instance URL
- the API key
- network connectivity
- whether the service is reachable from the device

If notifications are not working, verify that ntfy is enabled and the topic is configured.

If the UI feels stale after a configuration change, reopen the affected screen or restart the app.

## Assistant usage
This knowledge base is the source of truth for the in-app assistant.

The assistant should answer questions about:
- how the app works
- where a feature lives
- what a screen does
- how settings and instances behave
- what is currently supported or not supported

The assistant should avoid inventing features that are not described here.
