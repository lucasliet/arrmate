/// Global constants used for API interactions across the app.
class ApiConstants {
  /// The current API version (v3).
  static const String apiVersion = 'v3';

  /// The base path for API requests.
  static const String apiPath = '/api/$apiVersion';

  /// Default timeout for standard API requests (10 seconds).
  static const Duration defaultTimeout = Duration(seconds: 10);

  /// Extended timeout for slower operations (5 minutes).
  static const Duration slowTimeout = Duration(seconds: 300);

  /// Timeout specifically for release searches (90 seconds).
  static const Duration releaseSearchTimeout = Duration(seconds: 90);

  /// Extended timeout for release searches on slower instances (3 minutes).
  static const Duration slowReleaseSearchTimeout = Duration(seconds: 180);

  /// Timeout for downloading a release (15 seconds).
  static const Duration releaseDownloadTimeout = Duration(seconds: 15);

  /// Delay used for debouncing search inputs (250ms).
  static const Duration debounceDelay = Duration(milliseconds: 250);

  /// Number of items to fetch per page for queue requests.
  static const int queuePageSize = 100;

  /// Number of items to fetch per page for history requests.
  static const int historyPageSize = 50;

  /// Number of days to include ahead of the current date for calendar views.
  static const int calendarDaysAhead = 45;

  /// Number of days to include before the current date for calendar views.
  static const int calendarDaysBehind = 45;
}
