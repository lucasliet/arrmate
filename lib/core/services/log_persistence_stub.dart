/// Stores application logs outside the in-memory diagnostic buffer.
abstract interface class LogPersistence {
  /// Prepares the persistence implementation.
  Future<void> initialize();

  /// Appends one already-redacted log [entry].
  Future<void> append(String entry);
}

/// Creates the bounded-memory web persistence implementation.
LogPersistence createLogPersistence() => _MemoryOnlyLogPersistence();

class _MemoryOnlyLogPersistence implements LogPersistence {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> append(String entry) async {}
}
