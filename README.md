shelf_dynamic_forwarder
A utility package for Dart's shelf framework that simplifies dynamic route composition and forwarding.

This package solves the complex problem of using dynamic path segments (like user IDs or tenant names) as part of your router's prefix, allowing you to rewrite the URI path to isolate your child handlers. All captured path parameters are automatically forwarded as x- prefixed HTTP headers.

Features
Dynamic Path Capture: Define arbitrary path parameters in your route pattern.

URI Rewriting: Correctly constructs an absolute URI with an isolated path (e.g., transforms /tenant/123/data to /data) to ensure child routers match correctly.

Parameter Forwarding: Automatically converts captured parameters (e.g., <userId>) into request headers (x-userId).

Handler Switching: Uses a map-based routing table to replace complex switch statements.

Installation
Add shelf_dynamic_forwarder to your pubspec.yaml:

dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  shelf_dynamic_forwarder: ^1.0.0

Usage
Use the createDynamicRouter function to wrap your child handlers.

1. Define Child Handlers
Your child handlers define their routes relative to the path segment they expect to receive (e.g., /filenames).

import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';

Router get filenamesRequest {
  final handler = Router();
  handler.get('/filenames', (Request req) {
    // Access forwarded parameters via headers
    final adminId = req.headers['x-adminId'] ?? 'N/A';
    // Add Your logic code here...
    return Response.ok('Admin: $adminId');
  });
  return handler;
}

Router get postMediaRequest {
  final handler = Router();
  handler.post('/media', (Request req) {
    // Access forwarded parameters via headers
    final adminId = req.headers['x-adminId'] ?? 'N/A';
    // Add Your logic code here...
    return Response.ok('Admin: $adminId');
  });
  return handler;
}


2. Configure the Dynamic Router
Define your top-level router using createDynamicRouter.

import 'package:shelf_dynamic_forwarder/shelf_dynamic_forwarder.dart';

// 1. Define the routes map: Path Segment -> Handler
final Map<String, Handler> dynamicRoutes = {
  // Add other handlers here...
  'filenames': filenamesRequest,
  'media': postMediaRequest, 
};

// 2. Create the dynamic router instance
Handler get router {
  final dynamicRouter = createDynamicRouter(
    // The route pattern MUST end with a capturing group for the path segment.
    routePattern: '/api/<adminId>/<index>/<path|.*>', // path or files
    routes: dynamicRoutes,
    pathSegmentKey: 'path', // (optional) Matches the name of the final group in routePattern
  );

  // 3. Return the dynamicRouter to main
  return dynamicRouter; 
}

// 4. Use router 
void main() {
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);
}

// Requesting /api/user1/42/filenames will now hit filenamesRequest()

Dynamic Parameters
The parameters captured in the routePattern (<adminId>, <index>) are automatically available in the child handler's request headers as x-adminId and x-index.
