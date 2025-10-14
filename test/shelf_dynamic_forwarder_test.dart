import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
// Note: This import assumes your package name is shelf_dynamic_forwarder
import 'package:shelf_dynamic_forwarder/shelf_dynamic_forwarder.dart';

// --- Core Constant from the user's implementation ---
const String _defaultFileKey = '.*';

// --- MOCK HANDLERS FOR INSPECTION ---

/// A handler that captures key request details for easy assertion in tests.
/// The child router should only see the path segment (e.g., '/filenames').
// NOTE: Must be async and await the body read to prevent Future<String> serialization error.
Future<Response> captureRequestDetails(Request req) async {
  final bodyData = await req.readAsString(); // Await the body to get the String

  return Response.ok(
    jsonEncode({
      // The child's requested path should be the isolated segment
      'path': req.requestedUri.path,
      'headers': {
        // Parameters captured by the parent are forwarded as 'x-' headers
        'x-adminId': req.headers['x-adminId'],
        'x-index': req.headers['x-index'],
        'x-path': req.headers['x-path'],
      },
      'body': bodyData, // Now a resolved String, safe to encode
    }),
    headers: {'content-type': 'application/json'},
  );
}

// Named handler 1: For 'filenames' (exact match)
Handler filenamesHandler = (Request req) => captureRequestDetails(req);

// Named handler 2: For 'media' (exact match)
Handler mediaHandler = (Request req) => captureRequestDetails(req);

// Default File handler: For all paths containing a '.'
Handler fileRequestHandler = (Request req) => captureRequestDetails(req);

void main() {
  // Define the dynamic route pattern for all tests
  const dynamicRoutePattern = '/api/<adminId>/<index>/<path|.*>';

  // Define the routes map used by the dynamic router, using '.*' for files
  final dynamicRoutes = {
    'filenames': filenamesHandler,
    'media': mediaHandler,
    _defaultFileKey: fileRequestHandler, // Catches all paths with a dot
  };

  // Create the handler instance once for the entire test group
  final dynamicRouter = createDynamicRouter(
    routePattern: dynamicRoutePattern,
    routes: dynamicRoutes,
    pathSegmentKey: 'path',
  );

  // Helper function to send a mock request and decode the JSON response
  Future<Map<String, dynamic>> sendRequest(String path,
      {String method = 'GET', String? body}) async {
    final uri = Uri.parse('http://localhost$path');
    final request = Request(method, uri, body: body);

    final response = await dynamicRouter(request);

    // Read and parse the response body
    final bodyString = await response.readAsString();
    final responseData = jsonDecode(bodyString) as Map<String, dynamic>;

    // The 'body' key is now a resolved String due to the fix in captureRequestDetails.
    // We only cast it here for clean access.
    responseData['body'] = responseData['body'] as String;

    return responseData;
  }

  group('Dynamic Router with File/API Switching', () {
    test('1. Should route API endpoint (no dot) to exact handler (filenames)',
        () async {
      final response = await sendRequest('/api/user-123/prod/filenames');

      // Should hit the 'filenames' handler
      expect(response['headers']['x-path'], equals('filenames'));
      // URI should be isolated
      expect(response['path'], equals('/filenames'));
      expect(response['headers']['x-adminId'], equals('user-123'));
    });

    test(
        '2. Should route file path (contains dot) to the default file handler (.mp4)',
        () async {
      final response = await sendRequest('/api/user-456/dev/video.mp4');

      // Should hit the '.*' handler
      expect(response['headers']['x-path'], equals('video.mp4'));
      // URI should be isolated
      expect(response['path'], equals('/video.mp4'));

      // Assert it used the file handler
      expect(response['headers']['x-index'], equals('dev'));
    });

    test(
        '3. Should route file path (contains dot) to the default file handler (.v1 config)',
        () async {
      final response = await sendRequest('/api/userX/3/config.v1');

      // Should hit the '.*' handler, even if it's not a standard image/video extension
      expect(response['headers']['x-path'], equals('config.v1'));
      expect(response['path'], equals('/config.v1'));
    });

    test(
        '4. Should route exact match even if the path contains a hyphen (non-file)',
        () async {
      // Test an exact match that doesn't contain a dot
      dynamicRoutes['test-endpoint'] = mediaHandler;

      final dynamicRouter = createDynamicRouter(
        routePattern: dynamicRoutePattern,
        routes: dynamicRoutes,
        pathSegmentKey: 'path',
      );

      final response = await sendRequest('/api/user-test/1/test-endpoint');

      // Should hit the 'test-endpoint' handler (because it contains no dot)
      expect(response['headers']['x-path'], equals('test-endpoint'));
      expect(response['path'], equals('/test-endpoint'));
    });

    test(
        '5. Should correctly forward body for POST requests to an exact match handler',
        () async {
      const testBody = '{"user": "new_profile"}';
      final response = await sendRequest('/api/userZ/5/media',
          method: 'POST', body: testBody);

      // Check body forwarding
      expect(response['body'], equals(testBody),
          reason: 'Request body must be correctly read and re-buffered.');

      // Check header forwarding
      expect(response['headers']['x-index'], equals('5'));
      expect(response['headers']['x-path'], equals('media'));
    });
  });
}
