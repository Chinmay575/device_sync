import 'dart:io';

abstract class _FileTransferServerRepository {
  Future<void> startHttpServer({
    required void Function(HttpRequest) onData,
    required void Function() onDone,
    required void Function() onError,
  });
}

class FileTransferServerRepository implements _FileTransferServerRepository {
  HttpServer? server;

  @override
  Future<void> startHttpServer({
    required void Function(HttpRequest) onData,
    required void Function() onDone,
    required void Function() onError,
  }) async {
    server = await .bind(InternetAddress.anyIPv4, 0);
    server?.listen(onData, onDone: onDone, onError: onError);
  }
}
