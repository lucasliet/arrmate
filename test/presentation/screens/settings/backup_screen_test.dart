import 'package:arrmate/core/services/backup_service.dart';
import 'package:arrmate/presentation/providers/backup_provider.dart';
import 'package:arrmate/presentation/screens/settings/backup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBackupNotifier extends BackupNotifier {
  BackupState fakeState;
  BackupPayload? previewPayload;
  bool signInCalled = false;
  bool signOutCalled = false;
  bool backupNowCalled = false;
  bool runAutoBackupCalled = false;
  bool restoreFromCalled = false;
  BackupPayload? restoredPayload;

  FakeBackupNotifier(this.fakeState);

  @override
  BackupState build() => fakeState;

  void emit(BackupState newState) {
    fakeState = newState;
    state = newState;
  }

  @override
  Future<void> signIn() async {
    signInCalled = true;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<void> backupNow() async {
    backupNowCalled = true;
  }

  @override
  Future<void> runAutoBackup() async {
    runAutoBackupCalled = true;
  }

  @override
  Future<BackupPayload?> fetchBackupPreview() async => previewPayload;

  @override
  Future<bool> restoreFrom(BackupPayload payload) async {
    restoreFromCalled = true;
    restoredPayload = payload;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shouldShowNotConfiguredCard_whenBuildLacksCredentials', (
    tester,
  ) async {
    // Given
    const state = BackupState(isConfigured: false);

    // When
    await _pumpScreen(tester, state);

    // Then
    expect(find.byKey(const Key('backupNotConfiguredCard')), findsOneWidget);
    expect(find.byKey(const Key('backupSignInButton')), findsNothing);
  });

  testWidgets('shouldShowSignInButton_whenSignedOut', (tester) async {
    // Given
    final notifier = FakeBackupNotifier(
      const BackupState(isConfigured: true, isSignedIn: false),
    );
    await _pumpScreen(tester, notifier.fakeState, notifier: notifier);

    // When
    await tester.tap(find.byKey(const Key('backupSignInButton')));
    await tester.pumpAndSettle();

    // Then
    expect(notifier.signInCalled, isTrue);
  });

  testWidgets('shouldShowAccountAndActions_whenSignedIn', (tester) async {
    // Given
    final lastBackupAt = DateTime.utc(2026, 3, 4, 5, 6);

    // When
    await _pumpScreen(tester, _signedInState(lastBackupAt: lastBackupAt));

    // Then
    expect(find.text('user@mail'), findsOneWidget);
    expect(find.byKey(const Key('backupNowButton')), findsOneWidget);
    expect(find.byKey(const Key('backupRestoreButton')), findsOneWidget);
    final expected = DateFormat('d MMM y HH:mm').format(lastBackupAt);
    expect(find.textContaining(expected), findsOneWidget);
    expect(find.textContaining('never'), findsNothing);
  });

  testWidgets('shouldShowNever_whenNoBackupYet', (tester) async {
    // Given
    await _pumpScreen(tester, _signedInState(lastBackupAt: null));

    // Then
    expect(find.textContaining('never'), findsOneWidget);
  });

  testWidgets('shouldRunBackup_whenBackUpNowTapped', (tester) async {
    // Given
    final notifier = FakeBackupNotifier(_signedInState());
    await _pumpScreen(tester, notifier.fakeState, notifier: notifier);

    // When
    await tester.tap(find.byKey(const Key('backupNowButton')));
    await tester.pumpAndSettle();

    // Then
    expect(notifier.backupNowCalled, isTrue);
  });

  testWidgets('shouldConfirmBeforeRestore_andCallRestoreFrom', (tester) async {
    // Given
    final payload = BackupPayload(
      schema: 1,
      appVersion: '2.3.0',
      platform: 'linux',
      createdAt: DateTime.utc(2026, 1, 2, 3),
      preferences: const <String, Object?>{},
    );
    final notifier = FakeBackupNotifier(_signedInState());
    notifier.previewPayload = payload;
    await _pumpScreen(tester, notifier.fakeState, notifier: notifier);

    // When
    await tester.tap(find.byKey(const Key('backupRestoreButton')));
    await tester.pumpAndSettle();

    // Then
    expect(find.byKey(const Key('backupRestoreConfirmDialog')), findsOneWidget);
    expect(find.text('App version: 2.3.0'), findsOneWidget);
    expect(find.text('Platform: linux'), findsOneWidget);
    expect(find.text('Instances: 0'), findsOneWidget);

    // When
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Then
    expect(notifier.restoreFromCalled, isFalse);

    // When
    await tester.tap(find.byKey(const Key('backupRestoreButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backupRestoreConfirmButton')));
    await tester.pumpAndSettle();

    // Then
    expect(notifier.restoreFromCalled, isTrue);
    expect(notifier.restoredPayload, same(payload));
    expect(find.text('Backup restored'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('shouldShowErrorMessage_inline', (tester) async {
    // Given
    await _pumpScreen(tester, _signedInState(errorMessage: 'Boom'));

    // Then
    expect(find.byKey(const Key('backupErrorMessage')), findsOneWidget);
    expect(find.text('Boom'), findsOneWidget);
  });
}

BackupState _signedInState({
  DateTime? lastBackupAt,
  String? errorMessage,
  String? statusMessage,
  bool isWorking = false,
}) {
  return BackupState(
    isConfigured: true,
    isSignedIn: true,
    accountEmail: 'user@mail',
    lastBackupAt: lastBackupAt,
    isWorking: isWorking,
    errorMessage: errorMessage,
    statusMessage: statusMessage,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  BackupState state, {
  FakeBackupNotifier? notifier,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backupProvider.overrideWith(
          () => notifier ?? FakeBackupNotifier(state),
        ),
      ],
      child: const MaterialApp(home: BackupScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
