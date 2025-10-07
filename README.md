# shelf_dynamic_forwarder

[![Pub](https://img.shields.io/pub/v/shelf_dynamic_forwarder.svg)](https://pub.dev/packages/shelf_dynamic_forwarder) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Dart](https://img.shields.io/badge/Dart-3.0-blue.svg)](https://dart.dev/) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/guibbv2011/shelf_dynamic_forwarder/pulls)

A utility package for Dart's [Shelf](https://pub.dev/packages/shelf) framework that simplifies dynamic route composition and forwarding.

This package solves the complex problem of using dynamic path segments (like user IDs or tenant names) as part of your router's prefix, allowing you to rewrite the URI path to isolate your child handlers. All captured path parameters are automatically forwarded as `x-` prefixed HTTP headers.

## ✨ Features

- **Dynamic Path Capture**: Define arbitrary path parameters in your route pattern.
- **URI Rewriting**: Correctly constructs an absolute URI with an isolated path (e.g., transforms `/tenant/123/data` to `/data`) to ensure child routers match correctly.
- **Parameter Forwarding**: Automatically converts captured parameters (e.g., `<userId>`) into request headers (`x-userId`).
- **Handler Switching**: Uses a map-based routing table to replace complex switch statements.

## 📦 Installation

Add `shelf_dynamic_forwarder` to your `pubspec.yaml`:

```yaml
dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  shelf_dynamic_forwarder: ^1.1.1
```

Then run:

```bash
dart pub get
```

## 🚀 Usage

Use the `createDynamicRouter` function to wrap your child handlers.

### 1. Define Child Handlers

Your child handlers define their routes relative to the path segment they expect to receive (e.g., `/filenames`).

```dart
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';

Router get filenamesRequest {
  final handler = Router();
  handler.get('/filenames', (Request req) {
    // Access forwarded parameters via headers
    final adminId = req.headers['x-adminId'] ?? 'N/A';
    // Add your logic code here...
    return Response.ok('Admin: $adminId');
  });
  return handler;
}

Router get postMediaRequest {
  final handler = Router();
  handler.post('/media', (Request req) {
    // Access forwarded parameters via headers
    final adminId = req.headers['x-adminId'] ?? 'N/A';
    // Add your logic code here...
    return Response.ok('Admin: $adminId');
  });
  return handler;
}

Router get deleteFileRequest {
  final handler = Router();
  handler.delete('/deleteFile', (Request req) {
    // Access forwarded parameters via headers
    final file = req.headers['x-path'] ?? 'N/A';
    // Add your logic code here...
    return Response.ok('file: $file');
  });
  return handler;
}
```

### 2. Configure the Dynamic Router

Define your top-level router using `createDynamicRouter`.

```dart
import 'package:shelf_dynamic_forwarder/shelf_dynamic_forwarder.dart';

// 1. Define the routes map: Path Segment -> Handler
final Map<String, Handler> dynamicRoutes = {
  // Add other handlers here...
  'deleteFile': deleteFileRequest, // default name to delete file
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
  // Serve the handler...
}
```

## 🔧 Dynamic Parameters

The parameters captured in the `routePattern` (`<adminId>`, `<index>`) are automatically available in the child handler's request headers as `x-adminId` and `x-index`.

### 📖 Example

**filenames Request**: Requesting `curl -X GET http://localhost:8080/api/user1/42/filenames` will now hit `filenamesRequest()`!

_**deleteFile Request Requesting**_ `curl -X DELETE http://localhost:8080/api/user/index/deleteFile/file.*` will now hit `deleteFileRequest()`!

**or**

_**To delete the entire index with files**_ `curl -X DELETE http://localhost:8080/api/user/index/deleteIndex`

For a full working example, check out the [example](example/) directory in the repository.

## 🤝 Contributing

1. Fork the project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with ❤️ using Dart and Shelf.
- Thanks to the [Shelf](https://pub.dev/packages/shelf) team for the amazing framework!

---

> **⭐ Star this repo if you found it useful!**  
> **💬 Have questions? Open an [issue](https://github.com/guibbv2011/shelf_dynamic_forwarder/issues) or join the discussion.**
