import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks errors that occur during the initial service setup.
final initializationErrorProvider = StateProvider<String?>((ref) => null);
