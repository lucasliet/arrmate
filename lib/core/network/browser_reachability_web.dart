import 'dart:js_interop';

@JS('fetch')
external JSPromise<JSAny?> _fetch(JSString resource, JSAny? options);

/// How long the probe waits before taking the server as unreachable.
const Duration _probeTimeout = Duration(seconds: 10);

/// Whether a server answers at [url], whatever the answer is.
///
/// A `no-cors` request hands back an opaque answer the app cannot read, yet it
/// only completes when the server did answer. That tells an answer the browser
/// blocked (CORS) apart from a server that is down, which a regular request
/// reports as the same connection error. No credentials are sent.
Future<bool> canBrowserReach(String url) async {
  try {
    final options = {
      'mode': 'no-cors',
      'credentials': 'omit',
      'cache': 'no-store',
    }.jsify();
    await _fetch(url.toJS, options).toDart.timeout(_probeTimeout);
    return true;
  } catch (_) {
    return false;
  }
}
