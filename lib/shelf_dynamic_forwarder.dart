import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const String _defaultFileKey = '.*';
const String _defaultDeleteFileKey = 'deleteFile';

/// A utility to create a shelf_router handler that forwards requests
/// based on dynamic path segments, rewriting the URI for child routers.
///
/// This resolves common issues with mounting dynamic segments by ensuring:
/// 1. All captured route parameters are forwarded as 'x-' prefixed headers.
/// 2. The Request URI is rewritten to an absolute, isolated path (e.g., /filenames),
///    allowing child routers to match against their base paths.
///
/// [routePattern]: The full dynamic pattern to capture, e.g., /<p1>/<p2>/<path|.*>.
///                 It MUST end with a capturing group that will be used for switching
///                 (defaulting to 'path', but can be overridden).
/// [routes]: A map where the key is the string value of the final path segment
///           (e.g., 'filenames') and the value is the corresponding [Handler].
/// [pathSegmentKey]: The name of the capturing group in [routePattern] used for
///                   switching between handlers (default: 'path').
Handler createDynamicRouter({
  required String routePattern,
  required Map<String, Handler> routes,
  String pathSegmentKey = 'path',
}) {
  final router = Router();

  // Use shelf_router.all to capture the request based on the dynamic pattern
  router.all(routePattern, (Request request) async {
    final routeParams = request.params;

    // 1. Get the path segment used for internal routing switch
    var pathSegment = routeParams[pathSegmentKey];
    if (pathSegment == null || pathSegment.isEmpty) {
      return Response.badRequest(
          body: 'Missing required path segment: $pathSegmentKey');
    }

    Handler? handler;

    if (pathSegment.contains('deleteFile/') && pathSegment.contains('.')) {
      handler = routes[_defaultDeleteFileKey];
      pathSegment = pathSegment.split('/').elementAt(0);
    } else if (pathSegment.contains('.')) {
      handler = routes[_defaultFileKey];
    } else {
      handler = routes[pathSegment];
    }

    // 2. Prepare headers: Forward all captured parameters with an 'x-' prefix
    final newHeaders = {
      ...request.headers,
    };

    routeParams.forEach((key, value) {
      if (key == 'path' && value.contains('deleteFile/')) {
        value = value.substring('deleteFile/'.length);
      }
      newHeaders['x-$key'] = value;
    });

    // 3. CRITICAL STEP: Create a new ABSOLUTE URI for the child router.
    // This isolates the child from the parent's base path and ensures the URI is absolute.
    final originalUri = request.requestedUri;

    final newUri = originalUri.replace(
      // Explicitly retain scheme, host, and port for absolute URI
      scheme: originalUri.scheme,
      userInfo: originalUri.userInfo,
      host: originalUri.host,
      port: originalUri.port,

      // Reset the path to only what the child router expects (e.g., /filenames)
      // pathSegments must be an Iterable<String>
      pathSegments: [pathSegment],

      queryParameters: originalUri.queryParameters,
      fragment: originalUri.fragment,
    );

    // 4. Create a brand new Request object using the new absolute URI.
    final subReq = Request(
      request.method,
      newUri,
      headers: newHeaders,
      body: await request.read(),
      context: request.context,
    );

    // 5. Execute it
    return await handler!(subReq);
  });

  return router;
}
