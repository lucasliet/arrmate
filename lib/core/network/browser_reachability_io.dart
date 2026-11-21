/// Whether a server answers at [url], whatever the answer is.
///
/// Only a browser hides answers from the app, so outside of one there is
/// nothing to probe and the server is taken as reachable.
Future<bool> canBrowserReach(String url) async => true;
