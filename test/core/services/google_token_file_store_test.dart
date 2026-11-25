import 'dart:io';

import 'package:arrmate/core/services/google_token_file_store.dart';
import 'package:arrmate/core/services/google_token_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory directory;
  late FileGoogleTokenStore store;

  File tokenFile() =>
      File(path.join(directory.path, FileGoogleTokenStore.fileName));

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('google_token_store');
    store = FileGoogleTokenStore(resolveDirectory: () async => directory);
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('returns an empty map when nothing was saved', () async {
    // When
    final values = await store.readAll();

    // Then
    expect(values, isEmpty);
  });

  test('merges saved values on top of the stored ones', () async {
    // Given
    await store.save({GoogleTokenKeys.refreshToken: 'refresh'});

    // When
    await store.save({GoogleTokenKeys.accessToken: 'access'});

    // Then
    expect(await store.readAll(), {
      GoogleTokenKeys.refreshToken: 'refresh',
      GoogleTokenKeys.accessToken: 'access',
    });
  });

  test('keeps every key when saves run concurrently', () async {
    // When
    await Future.wait([
      store.save({GoogleTokenKeys.pendingVerifier: 'verifier'}),
      store.save({GoogleTokenKeys.pendingState: 'state'}),
    ]);

    // Then
    expect(await store.readAll(), {
      GoogleTokenKeys.pendingVerifier: 'verifier',
      GoogleTokenKeys.pendingState: 'state',
    });
  });

  test('restores the values from a new store instance', () async {
    // Given
    await store.save({GoogleTokenKeys.refreshToken: 'refresh'});
    final reopened = FileGoogleTokenStore(
      resolveDirectory: () async => directory,
    );

    // When
    final values = await reopened.readAll();

    // Then
    expect(values, {GoogleTokenKeys.refreshToken: 'refresh'});
  });

  test('clear removes the token file', () async {
    // Given
    await store.save({GoogleTokenKeys.refreshToken: 'refresh'});

    // When
    await store.clear();

    // Then
    expect(await store.readAll(), isEmpty);
    expect(tokenFile().existsSync(), isFalse);
  });

  test('ignores a token file that is not a JSON object', () async {
    // Given
    await tokenFile().writeAsString('[1, 2]');

    // When
    final values = await store.readAll();

    // Then
    expect(values, isEmpty);
  });

  test(
    'writes the token file readable only by its owner',
    () async {
      // When
      await store.save({GoogleTokenKeys.refreshToken: 'refresh'});

      // Then
      expect(tokenFile().statSync().modeString(), 'rw-------');
    },
    skip: Platform.isWindows ? 'POSIX permissions only' : false,
  );
}
