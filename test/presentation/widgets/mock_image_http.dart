import 'dart:async';
import 'dart:io';
import 'package:mocktail/mocktail.dart';

class FakeUri extends Fake implements Uri {}

void registerMockFallbacks() {
  registerFallbackValue(FakeUri());
}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _createMockImageHttpClient();
  }
}

HttpClient _createMockImageHttpClient() {
  final client = _MockHttpClient();
  return client;
}

class _MockHttpClient extends Mock implements HttpClient {
  _MockHttpClient() {
    when(() => getUrl(any())).thenAnswer((_) async => _MockHttpClientRequest());
  }
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  _MockHttpClientRequest() {
    when(() => headers).thenReturn(_MockHttpHeaders());
    when(() => close()).thenAnswer((_) async => _MockHttpClientResponse());
  }
}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  _MockHttpClientResponse() {
    when(() => statusCode).thenReturn(200);
    when(() => contentLength).thenReturn(_transparentImage.length);
    when(() => compressionState).thenReturn(HttpClientResponseCompressionState.notCompressed);
    when(() => listen(
          any(),
          onDone: any(named: 'onDone'),
          onError: any(named: 'onError'),
          cancelOnError: any(named: 'cancelOnError'),
        )).thenAnswer((invocation) {
      final onData = invocation.positionalArguments[0] as void Function(List<int>);
      final onDone = invocation.namedArguments['onDone'] as void Function()?;
      onData(_transparentImage);
      onDone?.call();
      return Stream<List<int>>.fromIterable([_transparentImage]).listen(null);
    });
  }
}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

final _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];
// Note: Proper mock image implementation is complex. 
// For this "meaningful test" request, we might just wrap with minimal overrides or 
// preferably use a library like `network_image_mock` but we don't have it.
// Simpler approach for widget test with network image: 
// Just check for the widgets existence and don't fail on 404s? 
// Actually flutter_test handles asset images fine, networking images throw 400.
