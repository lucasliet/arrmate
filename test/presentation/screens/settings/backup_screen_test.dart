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
  BackupPayload? filePreviewPayload;
  String? exportResult;
  String? importError;
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
  Future<String?> exportToFile() async => exportResult;

  @override
  Future<BackupPayload?> importFilePreview() async {
    if (importError != null) {
      emit(fakeState.copyWith(errorMessage: importError));
    }
    return filePreviewPayload;
  }

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

  testWidgets('shouldShowSignInError_whenSignedOut', (tester) async {
    // Given
    const state = BackupState(
      isConfigured: true,
      isSignedIn: false,
      errorMessage: 'Sign-in failed. Check your connection and try again.',
    );

    // When
    await _pumpScreen(tester, state);

    // Then
    expect(find.byKey(const Key('backupSignInButton')), findsOneWidget);
    expect(find.byKey(const Key('backupErrorMessage')), findsOneWidget);
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

  testWidgets('shouldOfferRestore_whenDriveHoldsUnrestoredBackup', (
    tester,
  ) async {
    // Given
    final remoteBackupAt = DateTime.utc(2026, 4, 2, 9, 30);
    final payload = BackupPayload(
      schema: 1,
      appVersion: '2.3.3',
      platform: 'ios',
      createdAt: remoteBackupAt,
      preferences: const <String, Object?>{},
    );
    final notifier = FakeBackupNotifier(
      BackupState(
        isConfigured: true,
        isSignedIn: true,
        accountEmail: 'user@mail',
        remoteBackupAt: remoteBackupAt,
      ),
    );
    notifier.previewPayload = payload;

    // When
    await _pumpScreen(tester, notifier.fakeState, notifier: notifier);

    // Then
    expect(find.byKey(const Key('backupRemoteBackupCard')), findsOneWidget);
    expect(find.textContaining('never'), findsNothing);
    final expected = DateFormat('d MMM y HH:mm').format(remoteBackupAt);
    expect(find.textContaining(expected), findsWidgets);

    // When
    await tester.ensureVisible(
      find.byKey(const Key('backupRemoteRestoreButton')),
    );
    await tester.tap(find.byKey(const Key('backupRemoteRestoreButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backupRestoreConfirmButton')));
    await tester.pumpAndSettle();

    // Then
    expect(notifier.restoreFromCalled, isTrue);
    expect(notifier.restoredPayload, same(payload));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('shouldHideRestoreOffer_whenDeviceIsInSync', (tester) async {
    // Given
    final backupAt = DateTime.utc(2026, 4, 2, 9, 30);
    final state = BackupState(
      isConfigured: true,
      isSignedIn: true,
      accountEmail: 'user@mail',
      lastBackupAt: backupAt,
      remoteBackupAt: backupAt,
      syncedRemoteAt: backupAt,
    );

    // When
    await _pumpScreen(tester, state);

    // Then
    expect(find.byKey(const Key('backupRemoteBackupCard')), findsNothing);
  });

  testWidgets('shouldShowErrorMessage_inline', (tester) async {
    // Given
    await _pumpScreen(tester, _signedInState(errorMessage: 'Boom'));

    // Then
    expect(find.byKey(const Key('backupErrorMessage')), findsOneWidget);
    expect(find.text('Boom'), findsOneWidget);
  });

  testWidgets('shouldShowLocalBackupActions_whenBuildLacksCredentials', (
    tester,
  ) async {
    // Given
    const state = BackupState(isConfigured: false);

    // When
    await _pumpScreen(tester, state);

    // Then
    expect(find.byKey(const Key('backupExportFileButton')), findsOneWidget);
    expect(find.byKey(const Key('backupImportFileButton')), findsOneWidget);
  });

  testWidgets('shouldShowExportedSnackbar_whenExportToFileTapped', (
    tester,
  ) async {
    // Given
    final notifier = FakeBackupNotifier(_signedInState());
    notifier.exportResult = 'arrmate-backup-2026-10-11.json';
    await _pumpScreen(tester, notifier.fakeState, notifier: notifier);

    // When
    await tester.ensureVisible(find.byKey(const Key('backupExportFileButton')));
    await tester.tap(find.byKey(const Key('backupExportFileButton')));
    await tester.pumpAndSettle();

    // Then
    expect(
      find.text('Backup exported to arrmate-backup-2026-10-11.json'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('shouldConfirmBeforeRestoreFromFile_andCallRestoreFrom', (
    tester,
  ) async {
    // Given
    final payload = BackupPayload(
      schema: 1,
      appVersion: '2.3.0',
      platform: 'android',
      createdAt: DateTime.utc(2026, 10, 11, 9),
      preferences: const <String, Object?>{},
    );
    final notifier = FakeBackupNotifier(_signedInState());
    notifier.filePreviewPayload = payload;
    await _pumpScreen(tester, notifier.fakeState, notifier: notifier);

    // When
    await tester.ensureVisible(find.byKey(const Key('backupImportFileButton')));
    await tester.tap(find.byKey(const Key('backupImportFileButton')));
    await tester.pumpAndSettle();

    // Then
    expect(find.byKey(const Key('backupRestoreConfirmDialog')), findsOneWidget);
    expect(find.text('Platform: android'), findsOneWidget);

    // When
    await tester.tap(find.byKey(const Key('backupRestoreConfirmButton')));
    await tester.pumpAndSettle();

    // Then
    expect(notifier.restoreFromCalled, isTrue);
    expect(notifier.restoredPayload, same(payload));
    expect(find.text('Backup restored'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('shouldShowErrorSnackbar_whenLocalFileInvalid', (tester) async {
    // Given
    final notifier = FakeBackupNotifier(const BackupState(isConfigured: false));
    notifier.importError =
        'The backup file is corrupted or from an unsupported version.';
    await _pumpScreen(tester, notifier.fakeState, notifier: notifier);

    // When
    await tester.ensureVisible(find.byKey(const Key('backupImportFileButton')));
    await tester.tap(find.byKey(const Key('backupImportFileButton')));
    await tester.pumpAndSettle();

    // Then
    expect(
      find.text('The backup file is corrupted or from an unsupported version.'),
      findsOneWidget,
    );
    expect(notifier.restoreFromCalled, isFalse);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
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
