extension StringExtensions on String {
  String trimmed() => trim();

  String get untrailingSlashIt {
    if (endsWith('/')) {
      return substring(0, length - 1);
    }
    return this;
  }

  String get withTrailingSlash {
    if (!endsWith('/')) {
      return '$this/';
    }
    return this;
  }

  bool get isValidUrl {
    final uri = Uri.tryParse(this);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

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

    if (firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31)
      return true;

    if (firstOctet == 192 && secondOctet == 168) return true;

    return false;
  }
}
