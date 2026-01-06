import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String get iso8601String => toIso8601String();

  String get shortDate => DateFormat.MMMd().format(this);

  String get longDate => DateFormat.yMMMd().format(this);

  String get timeOnly => DateFormat.Hm().format(this);

  String get dayName => DateFormat.EEEE().format(this);

  String get shortDayName => DateFormat.E().format(this);

  String get monthYear => DateFormat.yMMM().format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool get isPast => isBefore(DateTime.now());

  bool get isFuture => isAfter(DateTime.now());

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

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
