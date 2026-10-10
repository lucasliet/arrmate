import 'dart:convert';

/// Builds the self-contained HTML page shown in the browser at the end of the
/// Google sign-in redirect, styled after the app's Material 3 theme.
///
/// [success] selects the "Signed in" or "Sign-in failed" state, and [message]
/// is plain text that gets HTML-escaped. When [returnUrl] is set (iOS and
/// Android) the page offers a "Return to Arrmate" button pointing to it; when
/// it is null (desktop) the page only shows the message.
String buildOAuthResultPage({
  required bool success,
  required String message,
  String? returnUrl,
}) {
  const escape = HtmlEscape();
  const escapeAttribute = HtmlEscape(HtmlEscapeMode.attribute);
  final badge = success
      ? '<div class="badge badge-ok" aria-hidden="true">$_checkIcon</div>'
      : '<div class="badge badge-err" aria-hidden="true">$_errorIcon</div>';
  final messageClass = success ? 'msg' : 'msg msg-error';
  final url = returnUrl;
  final action = url == null
      ? ''
      : '<a class="btn" href="${escapeAttribute.convert(url)}">Return to Arrmate</a>';

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src data:">
<title>Arrmate</title>
<style>$_css</style>
</head>
<body>
<main class="card">
  <div class="brand">Arrmate</div>
  <div class="result" role="status" aria-live="polite">
    $badge
    <h1 class="title">${success ? 'Signed in' : 'Sign-in failed'}</h1>
    <p class="$messageClass">${escape.convert(message)}</p>
  </div>
  $action
</main>
</body>
</html>
''';
}

const _css = r'''
:root {
  --primary: #36618e; --on-primary: #ffffff; --primary-container: #d1e4ff;
  --on-primary-container: #194975; --surface: #f8f9ff; --card: #f2f3fa;
  --on-surface: #191c20; --on-surface-variant: #43474e;
  --outline-variant: #c3c7cf; --error-container: #ffdad6;
  --on-error-container: #93000a;
}
@media (prefers-color-scheme: dark) {
  :root {
    --primary: #a0cafd; --on-primary: #003258; --primary-container: #194975;
    --on-primary-container: #d1e4ff; --surface: #111418; --card: #191c20;
    --on-surface: #e1e2e8; --on-surface-variant: #c3c7cf;
    --outline-variant: #43474e; --error-container: #93000a;
    --on-error-container: #ffdad6;
  }
}
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body {
  min-height: 100vh; min-height: 100dvh;
  display: flex; align-items: center; justify-content: center;
  padding: 24px 16px;
  background: var(--surface); color: var(--on-surface);
  font-family: Roboto, system-ui, -apple-system, "Segoe UI", sans-serif;
  font-size: 15px; line-height: 1.5;
}
.card {
  width: 100%; max-width: 24rem; padding: 24px;
  background: var(--card);
  border: 1px solid var(--outline-variant); border-radius: 16px;
  text-align: center;
}
@media (prefers-reduced-motion: no-preference) {
  .card { animation: card-in 320ms cubic-bezier(.2, 0, 0, 1) both; }
  @keyframes card-in { from { opacity: 0; transform: translateY(8px) scale(.98); } }
}
@media (prefers-reduced-motion: reduce) {
  * { animation: none !important; transition: none !important; }
}
.brand {
  margin-bottom: 24px; user-select: none;
  color: var(--primary); font-size: 14px; font-weight: 600;
  letter-spacing: .02em;
}
.result { display: flex; flex-direction: column; align-items: center; }
.badge {
  width: 56px; height: 56px; margin-bottom: 16px;
  border-radius: 50%; display: flex; align-items: center; justify-content: center;
  user-select: none;
}
.badge svg { width: 32px; height: 32px; fill: currentColor; }
.badge-ok { background: var(--primary-container); color: var(--on-primary-container); }
.badge-err { background: var(--error-container); color: var(--on-error-container); }
.title { margin: 0 0 8px; font-size: 22px; line-height: 28px; font-weight: 500; }
.msg { margin: 0; color: var(--on-surface-variant); font-size: 14px; }
.msg-error {
  padding: 12px 16px; border-radius: 12px;
  background: var(--error-container); color: var(--on-error-container);
}
.btn {
  display: flex; align-items: center; justify-content: center;
  width: 100%; min-height: 48px; margin-top: 24px; padding: 0 24px;
  border-radius: 999px; background: var(--primary); color: var(--on-primary);
  font-size: 15px; font-weight: 600; text-decoration: none;
  position: relative; overflow: hidden; user-select: none;
  -webkit-tap-highlight-color: transparent;
}
.btn::after {
  content: ""; position: absolute; inset: 0; border-radius: inherit;
  background: var(--on-primary); opacity: 0; transition: opacity 150ms;
}
.btn:hover::after { opacity: .08; }
.btn:active::after { opacity: .12; }
.btn:focus-visible { outline: 2px solid var(--primary); outline-offset: 3px; }
''';

const _checkIcon =
    '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">'
    '<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 '
    '12 2zm-2 15-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>';

const _errorIcon =
    '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">'
    '<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 '
    '12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>';
