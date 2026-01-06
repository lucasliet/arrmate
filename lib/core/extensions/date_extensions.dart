import 'package:intl/intl.dart';

/// Extensions for [DateTime] providing formatting and utility checks.
extension DateTimeExtensions on DateTime {
  /// Returns the ISO-8601 string representation.
  String get iso8601String => toIso8601String();

  /// Formats date as short date (e.g., "Jan 1").
  String get shortDate => DateFormat.MMMd().format(this);

  /// Formats date as long date (e.g., "Jan 1, 2023").
  String get longDate => DateFormat.yMMMd().format(this);

  /// Formats time in hours and minutes (e.g., "14:30").
  String get timeOnly => DateFormat.Hm().format(this);

  /// Returns the full name of the day (e.g., "Monday").
  String get dayName => DateFormat.EEEE().format(this);

  /// Returns the abbreviated name of the day (e.g., "Mon").
  String get shortDayName => DateFormat.E().format(this);

  /// Formats as Month Year (e.g., "Jan 2023").
  String get monthYear => DateFormat.yMMM().format(this);

  /// Checks if the date represents today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if the date represents tomorrow.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Checks if the date is in the past.
  bool get isPast => isBefore(DateTime.now());

  /// Checks if the date is in the future.
  bool get isFuture => isAfter(DateTime.now());

  /// Checks if this date falls on the same day as [other].
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns a new [DateTime] representing the start of this day (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns a new [DateTime] representing the end of this day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns a relative date string (e.g., "Just now", "2d ago", "Yesterday").
  String get relativeDate {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    }
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    }

    return '${(difference.inDays / 365).floor()}y ago';
  }
}
