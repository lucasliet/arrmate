import 'package:arrmate/core/services/backup_service.dart';
import 'package:arrmate/core/services/google_auth.dart';
import 'package:arrmate/core/services/google_drive_service.dart';
import 'package:arrmate/core/services/google_oauth_service.dart';
import 'package:arrmate/presentation/providers/backup_provider.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGoogleOAuthService extends Mock implements GoogleOAuthService {}

class _MockGoogleDriveService extends Mock implements GoogleDriveService {}

class _MockBackupService extends Mock implements BackupService {}

class _CountingInstancesNotifier extends InstancesNotifier {
  static int buildCount = 0;

  @override
  InstancesState build() {
    buildCount++;
    return super.build();
  }
}

void main() {
  late _MockGoogleOAuthService oauthService;
  late _MockGoogleDriveService driveService;
  late _MockBackupService backupService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _CountingInstancesNotifier.buildCount = 0;
    oauthService = _MockGoogleOAuthService();
    driveService = _MockGoogleDriveService();
    backupService = _MockBackupService();
    when(() => driveService.findBackupFile()).thenAnswer((_) async => null);
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer({List<Override> overrides = const []}) {
    container = ProviderContainer(
      overrides: [
        googleOAuthServiceProvider.overrideWithValue(oauthService),
        googleDriveServiceProvider.overrideWithValue(driveService),
        backupServiceProvider.overrideWithValue(backupService),
        ...overrides,
      ],
    );
    return container;
  }

  group('BackupNotifier', () {
    test('shouldRestoreSessionAndLastBackupOnBuild', () async {
      // Given
      final lastBackupAt = DateTime.utc(2026, 1, 15, 10, 30);
      SharedPreferences.setMockInitialValues({
        BackupNotifier.lastBackupKey: lastBackupAt.toIso8601String(),
      });
      when(
        () => oauthService.restoreSession(),
      ).thenAnswer((_) async => const GoogleAccount(email: 'user@mail.com'));

      // When
      createContainer(
        overrides: [backupConfiguredProvider.overrideWithValue(true)],
      );
      container.read(backupProvider);
      await Future<void>.delayed(Duration.zero);

      // Then
      final state = container.read(backupProvider);
      expect(state.isConfigured, isTrue);
      expect(state.isSignedIn, isTrue);
      expect(state.accountEmail, 'user@mail.com');
      expect(state.lastBackupAt, lastBackupAt);
      verify(() => oauthService.restoreSession()).called(1);
    });

    test('shouldSignInSuccessfully', () async {
      // Given
      createContainer();
      when(
        () => oauthService.signIn(),
      ).thenAnswer((_) async => const GoogleAccount(email: 'user@mail.com'));

      // When
      await container.read(backupProvider.notifier).signIn();

      // Then
      final state = container.read(backupProvider);
      expect(state.isSignedIn, isTrue);
      expect(state.accountEmail, 'user@mail.com');
      expect(state.isWorking, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('shouldSetRedirectStatus_whenWebRedirectPending', () async {
      // Given
      createContainer();
      when(
        () => oauthService.signIn(),
      ).thenThrow(const GoogleOAuthRedirectPending());

      // When
      await container.read(backupProvider.notifier).signIn();

      // Then
      final state = container.read(backupProvider);
      expect(state.statusMessage, isNotNull);
      expect(state.isSignedIn, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isWorking, isFalse);
    });

    test('shouldUploadPayloadAndPersistLastBackup_onBackupNow', () async {
      // Given
      createContainer();
      when(
        () => oauthService.signIn(),
      ).thenAnswer((_) async => const GoogleAccount(email: 'user@mail.com'));
      await container.read(backupProvider.notifier).signIn();

      final createdAt = DateTime.utc(2026, 3, 1, 8, 0);
      final payload = BackupPayload(
        schema: 1,
        appVersion: '1.0.0',
        platform: 'android',
        createdAt: createdAt,
        preferences: const {},
      );
      when(
        () => backupService.createPayload(),
      ).thenAnswer((_) async => payload);
      when(() => driveService.uploadBackup(any())).thenAnswer(
        (_) async => DriveBackupInfo(id: 'backup-1', modifiedTime: createdAt),
      );

      // When
      await container.read(backupProvider.notifier).backupNow();

      // Then
      final state = container.read(backupProvider);
      expect(state.lastBackupAt, createdAt);
      expect(state.statusMessage, 'Backup completed.');
      expect(state.errorMessage, isNull);
      expect(state.isWorking, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(BackupNotifier.lastBackupKey),
        createdAt.toIso8601String(),
      );
      verify(
        () => driveService.uploadBackup(payload.toEncodedJson()),
      ).called(1);
    });

    test('shouldRefuseBackup_whenSignedOut', () async {
      // Given
      createContainer();

      // When
      await container.read(backupProvider.notifier).backupNow();

      // Then
      final state = container.read(backupProvider);
      expect(state.errorMessage, 'Sign in to Google first.');
      expect(state.isWorking, isFalse);
      verifyNever(() => backupService.createPayload());
      verifyNever(() => driveService.uploadBackup(any()));
    });

    test('shouldReturnNull_withNoBackupError_whenDriveHasNoFile', () async {
      // Given
      createContainer();
      when(
        () => driveService.downloadBackup(),
      ).thenThrow(const DriveBackupNotFoundException());

      // When
      final preview = await container
          .read(backupProvider.notifier)
          .fetchBackupPreview();

      // Then
      expect(preview, isNull);
      final state = container.read(backupProvider);
      expect(state.errorMessage, 'No backup found in your Google Drive.');
      expect(state.isWorking, isFalse);
    });

    test('shouldInvalidateProviders_andRestoreSummary_onRestoreFrom', () async {
      // Given
      createContainer(
        overrides: [
          instancesProvider.overrideWith(_CountingInstancesNotifier.new),
        ],
      );
      container.read(instancesProvider);
      await Future<void>.delayed(Duration.zero);
      expect(_CountingInstancesNotifier.buildCount, 1);

      final payload = BackupPayload(
        schema: 1,
        appVersion: '1.0.0',
        platform: 'android',
        createdAt: DateTime.utc(2026, 3, 1, 8, 0),
        preferences: const {},
      );
      when(() => backupService.restore(payload)).thenAnswer(
        (_) async => const BackupRestoreSummary(
          restoredKeys: 4,
          removedKeys: 0,
          instanceCount: 2,
        ),
      );

      // When
      final restored = await container
          .read(backupProvider.notifier)
          .restoreFrom(payload);
      container.read(instancesProvider);

      // Then
      expect(restored, isTrue);
      verify(() => backupService.restore(payload)).called(1);
      expect(container.read(backupAutoBackupSuppressedProvider), isTrue);
      expect(_CountingInstancesNotifier.buildCount, greaterThanOrEqualTo(2));
      final state = container.read(backupProvider);
      expect(state.statusMessage, 'Restored 4 settings and 2 instances.');
      expect(state.errorMessage, isNull);
      expect(state.isWorking, isFalse);
    });

    test('shouldSkipAutoBackup_whenSuppressed', () async {
      // Given
      createContainer();
      when(
        () => oauthService.signIn(),
      ).thenAnswer((_) async => const GoogleAccount(email: 'user@mail.com'));
      await container.read(backupProvider.notifier).signIn();
      container.read(backupAutoBackupSuppressedProvider.notifier).state = true;

      // When
      await container.read(backupProvider.notifier).runAutoBackup();

      // Then
      verifyNever(() => backupService.createPayload());
      verifyNever(() => driveService.uploadBackup(any()));
    });

    group('remote backup', () {
      final remoteModifiedAt = DateTime.utc(2026, 4, 2, 9, 0);

      void stubRemoteBackup(DateTime? modifiedTime) {
        when(() => driveService.findBackupFile()).thenAnswer(
          (_) async => modifiedTime == null
              ? null
              : DriveBackupInfo(id: 'remote-1', modifiedTime: modifiedTime),
        );
      }

      void stubSignIn() {
        when(
          () => oauthService.signIn(),
        ).thenAnswer((_) async => const GoogleAccount(email: 'user@mail.com'));
      }

      BackupPayload buildPayload(DateTime createdAt) => BackupPayload(
        schema: 1,
        appVersion: '1.0.0',
        platform: 'ios',
        createdAt: createdAt,
        preferences: const {},
      );

      test('shouldOfferRestore_whenSignInFindsBackupOnFreshDevice', () async {
        // Given
        createContainer();
        stubSignIn();
        stubRemoteBackup(remoteModifiedAt);

        // When
        await container.read(backupProvider.notifier).signIn();

        // Then
        final state = container.read(backupProvider);
        expect(state.remoteBackupAt, remoteModifiedAt);
        expect(state.lastBackupAt, isNull);
        expect(state.hasRemoteBackupToRestore, isTrue);
      });

      test('shouldNotOfferRestore_whenDriveHasNoBackup', () async {
        // Given
        createContainer();
        stubSignIn();
        stubRemoteBackup(null);

        // When
        await container.read(backupProvider.notifier).signIn();

        // Then
        final state = container.read(backupProvider);
        expect(state.remoteBackupAt, isNull);
        expect(state.hasRemoteBackupToRestore, isFalse);
      });

      test(
        'shouldNotOfferRestore_whenDeviceBackedUpBeforeTrackingSync',
        () async {
          // Given
          SharedPreferences.setMockInitialValues({
            BackupNotifier.lastBackupKey: DateTime.utc(
              2026,
              4,
              1,
            ).toIso8601String(),
          });
          createContainer(
            overrides: [backupConfiguredProvider.overrideWithValue(true)],
          );
          when(() => oauthService.restoreSession()).thenAnswer(
            (_) async => const GoogleAccount(email: 'user@mail.com'),
          );
          stubRemoteBackup(remoteModifiedAt);

          // When
          container.read(backupProvider);
          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);

          // Then
          final state = container.read(backupProvider);
          expect(state.remoteBackupAt, remoteModifiedAt);
          expect(state.hasRemoteBackupToRestore, isFalse);
        },
      );

      test('shouldOfferRestore_whenAnotherDeviceBackedUpAfterSync', () async {
        // Given
        SharedPreferences.setMockInitialValues({
          BackupNotifier.lastBackupKey: DateTime.utc(
            2026,
            4,
            1,
          ).toIso8601String(),
          BackupNotifier.syncedRemoteBackupKey: DateTime.utc(
            2026,
            4,
            1,
            0,
            0,
            5,
          ).toIso8601String(),
        });
        createContainer(
          overrides: [backupConfiguredProvider.overrideWithValue(true)],
        );
        when(
          () => oauthService.restoreSession(),
        ).thenAnswer((_) async => const GoogleAccount(email: 'user@mail.com'));
        stubRemoteBackup(remoteModifiedAt);

        // When
        container.read(backupProvider);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // Then
        expect(container.read(backupProvider).hasRemoteBackupToRestore, isTrue);
      });

      test('shouldSkipAutoBackup_whenRemoteBackupIsNotRestored', () async {
        // Given
        createContainer();
        stubSignIn();
        stubRemoteBackup(remoteModifiedAt);
        await container.read(backupProvider.notifier).signIn();

        // When
        await container.read(backupProvider.notifier).runAutoBackup();

        // Then
        verifyNever(() => backupService.createPayload());
        verifyNever(() => driveService.uploadBackup(any()));
      });

      test('shouldMarkSynced_andPersist_afterRestoreFrom', () async {
        // Given
        createContainer();
        stubSignIn();
        stubRemoteBackup(remoteModifiedAt);
        await container.read(backupProvider.notifier).signIn();
        final payload = buildPayload(DateTime.utc(2026, 4, 2, 8, 59));
        when(() => backupService.restore(payload)).thenAnswer(
          (_) async => const BackupRestoreSummary(
            restoredKeys: 3,
            removedKeys: 0,
            instanceCount: 1,
          ),
        );

        // When
        final restored = await container
            .read(backupProvider.notifier)
            .restoreFrom(payload);

        // Then
        expect(restored, isTrue);
        final state = container.read(backupProvider);
        expect(state.hasRemoteBackupToRestore, isFalse);
        expect(state.lastBackupAt, payload.createdAt);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(BackupNotifier.syncedRemoteBackupKey),
          remoteModifiedAt.toIso8601String(),
        );
      });

      test('shouldMarkSynced_afterBackupNow', () async {
        // Given
        createContainer();
        stubSignIn();
        stubRemoteBackup(remoteModifiedAt);
        await container.read(backupProvider.notifier).signIn();
        final payload = buildPayload(DateTime.utc(2026, 4, 3, 10, 0));
        final uploadedAt = DateTime.utc(2026, 4, 3, 10, 0, 2);
        when(
          () => backupService.createPayload(),
        ).thenAnswer((_) async => payload);
        when(() => driveService.uploadBackup(any())).thenAnswer(
          (_) async =>
              DriveBackupInfo(id: 'remote-1', modifiedTime: uploadedAt),
        );

        // When
        await container.read(backupProvider.notifier).backupNow();

        // Then
        final state = container.read(backupProvider);
        expect(state.remoteBackupAt, uploadedAt);
        expect(state.hasRemoteBackupToRestore, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(BackupNotifier.syncedRemoteBackupKey),
          uploadedAt.toIso8601String(),
        );
      });

      test('shouldKeepSignedIn_whenRemoteCheckFailsUnexpectedly', () async {
        // Given
        createContainer();
        stubSignIn();
        when(() => driveService.findBackupFile()).thenThrow(Exception('boom'));

        // When
        await container.read(backupProvider.notifier).signIn();

        // Then
        final state = container.read(backupProvider);
        expect(state.isSignedIn, isTrue);
        expect(state.errorMessage, isNull);
        expect(state.hasRemoteBackupToRestore, isFalse);
      });

      test(
        'shouldReportExpiredSession_whenRemoteCheckIsUnauthorized',
        () async {
          // Given
          createContainer();
          stubSignIn();
          when(
            () => driveService.findBackupFile(),
          ).thenThrow(const DriveAuthException());

          // When
          await container.read(backupProvider.notifier).signIn();

          // Then
          final state = container.read(backupProvider);
          expect(state.isSignedIn, isFalse);
          expect(state.errorMessage, 'Google session expired. Sign in again.');
        },
      );
    });
  });
}
