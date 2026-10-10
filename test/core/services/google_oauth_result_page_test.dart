import 'package:arrmate/core/services/google_oauth_result_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildOAuthResultPage', () {
    test('shouldShowSignedInTitleAndReturnButton_whenSuccessWithReturnUrl', () {
      // Given
      const returnUrl = 'arrmate-oauth://done';

      // When
      final page = buildOAuthResultPage(
        success: true,
        message: 'Sign-in complete. You can return to the app.',
        returnUrl: returnUrl,
      );

      // Then
      expect(page, contains('<h1 class="title">Signed in</h1>'));
      expect(page, contains('badge-ok'));
      expect(page, contains('<a class="btn" href="$returnUrl">'));
      expect(page, contains('Return to Arrmate'));
      expect(page, contains('Sign-in complete. You can return to the app.'));
    });

    test('shouldOmitButtonAndScripts_whenNoReturnUrl', () {
      // When
      final page = buildOAuthResultPage(success: true, message: 'Done');

      // Then
      expect(page, isNot(contains('<a class="btn"')));
      expect(page, isNot(contains('<script')));
      expect(page, isNot(contains('window.close')));
    });

    test('shouldShowFailureStyling_whenNotSuccessful', () {
      // When
      final page = buildOAuthResultPage(success: false, message: 'Denied');

      // Then
      expect(page, contains('<h1 class="title">Sign-in failed</h1>'));
      expect(page, contains('badge-err'));
      expect(page, contains('<p class="msg msg-error">Denied</p>'));
    });

    test('shouldEscapeMessageAndReturnUrl', () {
      // When
      final page = buildOAuthResultPage(
        success: false,
        message: '<script>alert(1)</script>',
        returnUrl: 'x" onclick="evil()',
      );

      // Then
      expect(page, isNot(contains('<script>alert(1)</script>')));
      expect(page, contains('&lt;script&gt;alert(1)&lt;&#47;script&gt;'));
      expect(page, isNot(contains('x" onclick="evil()')));
    });

    test('shouldFollowThemeAndStayOffline', () {
      // When
      final page = buildOAuthResultPage(success: true, message: 'Done');

      // Then
      expect(page, contains('--primary: #36618e'));
      expect(page, contains('prefers-color-scheme: dark'));
      expect(page, contains("default-src 'none'"));
      expect(page, isNot(contains('http://')));
      expect(page, isNot(contains('https://')));
    });
  });
}
