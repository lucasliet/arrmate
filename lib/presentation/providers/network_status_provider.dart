import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Current platform network availability and last known online time.
class NetworkAvailability extends Equatable {
  final List<ConnectivityResult> interfaces;
  final DateTime observedAt;
  final DateTime? lastOnlineAt;

  const NetworkAvailability({
    required this.interfaces,
    required this.observedAt,
    this.lastOnlineAt,
  });

  /// Whether the platform reports no available network interface.
  bool get isOffline =>
      interfaces.isEmpty ||
      interfaces.every((result) => result == ConnectivityResult.none);

  @override
  List<Object?> get props => [interfaces, observedAt, lastOnlineAt];
}

/// Connectivity implementation used for online status monitoring.
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// Live platform network state with a persisted last-online timestamp.
final networkAvailabilityProvider = StreamProvider<NetworkAvailability>((
  ref,
) async* {
  const lastOnlineKey = 'network_last_online_at';
  final connectivity = ref.watch(connectivityProvider);
  final preferences = await SharedPreferences.getInstance();
  DateTime? lastOnlineAt = DateTime.tryParse(
    preferences.getString(lastOnlineKey) ?? '',
  );

  Future<NetworkAvailability> createAvailability(
    List<ConnectivityResult> interfaces,
  ) async {
    final observedAt = DateTime.now();
    final isOnline =
        interfaces.isNotEmpty &&
        interfaces.any((result) => result != ConnectivityResult.none);
    if (isOnline) {
      lastOnlineAt = observedAt;
      await preferences.setString(lastOnlineKey, observedAt.toIso8601String());
    }
    return NetworkAvailability(
      interfaces: interfaces,
      observedAt: observedAt,
      lastOnlineAt: lastOnlineAt,
    );
  }

  yield await createAvailability(await connectivity.checkConnectivity());
  await for (final interfaces in connectivity.onConnectivityChanged) {
    yield await createAvailability(interfaces);
  }
});
