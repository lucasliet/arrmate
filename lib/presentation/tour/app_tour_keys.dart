import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the stable [GlobalKey]s used by the guided tour to locate target
/// widgets across screens.
///
/// Because targets live on different routes (Movies, Settings, Instance Edit),
/// a key is only meaningful while its owning screen is mounted. The tour
/// service navigates to the right route before referencing each key.
class AppTourKeys {
  final GlobalKey settingsInstancesHeaderKey = GlobalKey();
  final GlobalKey settingsAddInstanceKey = GlobalKey();
  final GlobalKey instanceTypeSelectorKey = GlobalKey();
  final GlobalKey instanceNameFieldKey = GlobalKey();
  final GlobalKey instanceUrlFieldKey = GlobalKey();
  final GlobalKey instanceApiKeyFieldKey = GlobalKey();
  final GlobalKey instanceTestConnectionKey = GlobalKey();
  final GlobalKey instanceSaveKey = GlobalKey();
  final GlobalKey moviesSearchKey = GlobalKey();
  final GlobalKey moviesSortKey = GlobalKey();

  /// First entry of the movie library, real or mocked by the tour.
  final GlobalKey moviesLibraryKey = GlobalKey();

  /// First entry of the series library, real or mocked by the tour.
  final GlobalKey seriesLibraryKey = GlobalKey();
  final GlobalKey calendarTitleKey = GlobalKey();

  /// First calendar event card, real or mocked by the tour.
  final GlobalKey calendarListKey = GlobalKey();
  final GlobalKey activityTabBarKey = GlobalKey();

  /// First download queue card, real or mocked by the tour.
  final GlobalKey activityQueueKey = GlobalKey();

  /// Torrents tab of the activity screen, shown by the tour even when no
  /// qBittorrent instance exists yet.
  final GlobalKey activityTorrentsTabKey = GlobalKey();

  /// First torrent card, real or mocked by the tour.
  final GlobalKey activityTorrentKey = GlobalKey();
  final GlobalKey navBarKey = GlobalKey();

  /// Returns `true` when [key]'s widget is currently mounted and renderable,
  /// i.e. its render box is available and has a non-zero size.
  static bool isReady(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return false;
    final box = ctx.findRenderObject();
    return box is RenderBox && box.hasSize && box.size != Size.zero;
  }
}

/// Provides a single long-lived [AppTourKeys] instance for the app.
final appTourKeysProvider = Provider<AppTourKeys>((ref) => AppTourKeys());
