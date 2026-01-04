import 'dart:math';

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';

  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (log(bytes) / log(1024)).floor();
  final value = bytes / pow(1024, i);

  return '${value.toStringAsFixed(i > 0 ? 1 : 0)} ${suffixes[i]}';
}

String formatRuntime(int minutes) {
  if (minutes <= 0) return '';

  final hours = minutes ~/ 60;
  final mins = minutes % 60;

  if (hours == 0) return '${mins}m';
  if (mins == 0) return '${hours}h';

  return '${hours}h ${mins}m';
}

String formatEpisodeNumber(int season, int episode, {bool short = false}) {
  if (short) {
    return 'S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}';
  }
  return 'Season $season, Episode $episode';
}

String formatSeasonNumber(int season) {
  if (season == 0) return 'Specials';
  return 'Season $season';
}

String formatPercentage(double value) {
  return '${value.toStringAsFixed(0)}%';
}

String formatProgress(int current, int total) {
  return '$current / $total';
}

String formatCustomScore(int score) {
  return score < 0 ? '$score' : '+$score';
}

String formatListWithSeparator(List<String> items, {String separator = ' · '}) {
  return items.where((item) => item.isNotEmpty).join(separator);
}

String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
