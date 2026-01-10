import 'dart:math';

/// Formats a byte size into a human-readable string (e.g., "1.5 MB").
///
/// [bytes] is the size in bytes to be formatted.
/// Returns a string representation with appropriate unit (B, KB, MB, GB, TB).
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';

  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (log(bytes) / log(1024)).floor();
  final value = bytes / pow(1024, i);

  return '${value.toStringAsFixed(i > 0 ? 1 : 0)} ${suffixes[i]}';
}

/// Formats a duration in minutes into a readable string (e.g., "1h 30m").
///
/// [minutes] is the duration in minutes.
/// Returns an empty string if [minutes] is less than or equal to 0.
String formatRuntime(int minutes) {
  if (minutes <= 0) return '';

  final hours = minutes ~/ 60;
  final mins = minutes % 60;

  if (hours == 0) return '${mins}m';
  if (mins == 0) return '${hours}h';

  return '${hours}h ${mins}m';
}

/// Formats a season and episode number.
///
/// [season] is the season number.
/// [episode] is the episode number.
/// [short] determines the format:
/// - false (default): "Season 1, Episode 5"
/// - true: "S01E05"
String formatEpisodeNumber(int season, int episode, {bool short = false}) {
  if (short) {
    return 'S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}';
  }
  return 'Season $season, Episode $episode';
}

/// Formats a season number.
///
/// Returns "Specials" if [season] is 0, otherwise "Season X".
String formatSeasonNumber(int season) {
  if (season == 0) return 'Specials';
  return 'Season $season';
}

/// Formats a double value as a percentage string without decimal places (e.g., "85%").
String formatPercentage(double value) {
  return '${value.toStringAsFixed(0)}%';
}

/// Formats a progress indicator string (e.g., "5 / 10").
///
/// [current] is the current progress value.
/// [total] is the total value.
String formatProgress(int current, int total) {
  return '$current / $total';
}

/// Formats a custom score, adding a plus sign for positive values (e.g., "+100").
///
/// [score] is the integer score.
String formatCustomScore(int score) {
  return score < 0 ? '$score' : '+$score';
}

/// Joins a list of strings with a separator, filtering out empty strings.
///
/// [items] is the list of strings to join.
/// [separator] defaults to ' · '.
String formatListWithSeparator(List<String> items, {String separator = ' · '}) {
  return items.where((item) => item.isNotEmpty).join(separator);
}

/// Formats a [DateTime] into a string in "YYYY-MM-DD" format.
String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Formats an instance version string.
///
/// Returns "{version}" if [version] starts with 'v'.
/// Otherwise, returns "v{version}".
/// Returns empty string if [version] is null or empty.
String formatInstanceVersion(String? version) {
  if (version == null || version.trim().isEmpty) return '';
  if (version.startsWith('v')) {
    return version;
  }
  return 'v$version';
}
