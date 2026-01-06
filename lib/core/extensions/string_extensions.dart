/// Extensions for [String] to handle common string manipulations and checks.
extension StringExtensions on String {
  /// Trims whitespace from both ends of the string.
  String trimmed() => trim();

  /// Removes the trailing slash from the string if it exists.
  String get untrailingSlashIt {
    if (endsWith('/')) {
      return substring(0, length - 1);
    }
    return this;
  }

  /// Appends a trailing slash to the string if it doesn't already have one.
  String get withTrailingSlash {
    if (!endsWith('/')) {
      return '$this/';
    }
    return this;
  }

  /// Checks if the string is a valid HTTP or HTTPS URL.
  bool get isValidUrl {
    final uri = Uri.tryParse(this);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  /// Checks if the string represents a private IP address (LAN).
  ///
  /// Covers 10.x.x.x, 172.16-31.x.x, 192.168.x.x, and localhost/127.0.0.1.
  bool get isPrivateIp {
    final uri = Uri.tryParse(this);
    if (uri == null || uri.host.isEmpty) return false;

    final host = uri.host;

    if (host == 'localhost' || host == '127.0.0.1') return true;

    final parts = host.split('.');
    if (parts.length != 4) return false;

    final firstOctet = int.tryParse(parts[0]);
    final secondOctet = int.tryParse(parts[1]);

    if (firstOctet == null || secondOctet == null) return false;

    if (firstOctet == 10) return true;

    if (firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31) {
      return true;
    }

    if (firstOctet == 192 && secondOctet == 168) return true;

    return false;
  }
}
