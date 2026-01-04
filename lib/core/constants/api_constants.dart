class ApiConstants {
  static const String apiVersion = 'v3';
  static const String apiPath = '/api/$apiVersion';

  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration slowTimeout = Duration(seconds: 300);
  static const Duration releaseSearchTimeout = Duration(seconds: 90);
  static const Duration slowReleaseSearchTimeout = Duration(seconds: 180);
  static const Duration releaseDownloadTimeout = Duration(seconds: 15);

  static const Duration debounceDelay = Duration(milliseconds: 250);

  static const int queuePageSize = 100;
  static const int historyPageSize = 50;

  static const int calendarDaysAhead = 45;
  static const int calendarDaysBehind = 45;
}
