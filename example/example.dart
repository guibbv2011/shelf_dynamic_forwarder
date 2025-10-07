import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_dynamic_forwarder/shelf_dynamic_forwarder.dart';
import 'package:shelf_router/shelf_router.dart';

Router get filenamesRequest {
  final handler = Router();
  handler.get('/filenames', (Request req) async {
    // Your logic code here..
    return Response.ok('');
  });
  return handler;
}

Router get fileRequest {
  final handler = Router();
  handler.post('/file', (Request req) async {
    // Your logic code here..
    return Response.ok('');
  });
  return handler;
}

Router get deleteFileRequest {
  final handler = Router();
  handler.delete('/deleteFile', (Request req) async {
    final file = req.headers['x-path'];
    // Your logic code here..
    return Response.ok('');
  });
  return handler;
}

Router get deleteIndexRequest {
  final handler = Router();
  handler.delete('/deleteIndex', (Request req) async {
    final index = req.headers['x-index'];
    // Your logic code here..
    return Response.ok('');
  });
  return handler;
}

final Map<String, Handler> dynamicRoutes = {
  'deleteIndex': deleteIndexRequest,
  'deleteFile': deleteFileRequest,
  'filenames': filenamesRequest,
  '.*': fileRequest,
};

Handler get router {
  final dynamicRouter = createDynamicRouter(
    routePattern: '/api/<adminId>/<index>/<path|.*>',
    routes: dynamicRoutes,
  );

  return dynamicRouter;
}

void main() async {
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  await serve(handler, 'localhost', 8080);
}
