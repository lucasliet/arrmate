import 'package:arrmate/core/services/legacy_web_google_token_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shouldRemoveLegacyWebGoogleOAuthTokens', () async {
    // Given
    SharedPreferences.setMockInitialValues({
      'google_oauth_tokens': '{"refresh_token":"stored"}',
      'home_tab': 'movies',
    });
    final prefs = await SharedPreferences.getInstance();

    // When
    await clearLegacyWebGoogleOAuthTokens(prefs);

    // Then
    expect(legacyWebGoogleOAuthTokensKey, 'google_oauth_tokens');
    expect(prefs.containsKey('google_oauth_tokens'), isFalse);
    expect(prefs.getString('home_tab'), 'movies');
  });

  test('shouldLeaveOtherPreferences_whenNoLegacyToken', () async {
    // Given
    SharedPreferences.setMockInitialValues({'home_tab': 'series'});
    final prefs = await SharedPreferences.getInstance();

    // When
    await clearLegacyWebGoogleOAuthTokens(prefs);

    // Then
    expect(prefs.getString('home_tab'), 'series');
    expect(prefs.containsKey('google_oauth_tokens'), isFalse);
  });
}
