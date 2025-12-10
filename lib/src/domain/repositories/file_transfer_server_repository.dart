import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mime/mime.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:archive/archive_io.dart';

abstract class _FileTransferServerRepository {
  void start();
  void stop();
}

class DesktopFileTransferRepository implements _FileTransferServerRepository {
  // Singleton
  DesktopFileTransferRepository._();
  static final DesktopFileTransferRepository instance =
      DesktopFileTransferRepository._();

  HttpServer? _server;
  final int _port = 8080;

  @override
  Future<void> start() async {
    if (_server != null) return;

    // Define Routes
    final app = Router();

    // 1. DOWNLOAD ROUTE: GET /download?path=/home/user/image.png
    app.get('/download', _handleDownload);

    // 2. UPLOAD ROUTE: POST /upload
    app.post('/upload', _handleUpload);

    // Start Server
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(app.call);
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);

    print('File Server running on port ${_server!.port}');
  }

  Future<Response> _handleDownload(Request request) async {
    // 1. Get path from query params
    final path = request.url.queryParameters['path'];
    if (path == null) return Response.badRequest(body: "Missing 'path' param");

    final file = File(path);
    if (!await file.exists()) return Response.notFound("File not found");

    // 2. Detect Mime Type (e.g., image/jpeg)
    final mimeType = lookupMimeType(path) ?? 'application/octet-stream';

    // 3. Stream the file (Efficient for large files)
    return Response.ok(
      file.openRead(),
      headers: {
        'Content-Type': mimeType,
        'Content-Disposition': 'attachment; filename="${path.split('/').last}"',
        'Content-Length': (await file.length()).toString(),
      },
    );
  }

  Future<Response> _handleUpload(Request request) async {
    // 1. Check if it's a Multipart Request

    final contentType = request.headers['content-type'];
    final isMultipart = contentType?.startsWith('multipart/form-data') ?? false;

    if (!isMultipart) {
      return Response.badRequest(body: "Not a multipart request");
    }

    // 2. Get the Destination Directory (Downloads)
    Directory? downloadsDir;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      downloadsDir = await getDownloadsDirectory();
    }

    // Fallback if path_provider fails on Linux sometimes
    if (downloadsDir == null) {
      String home = Platform.environment['HOME'] ?? '/';
      downloadsDir = Directory('$home/Downloads');
    }

    if (request.formData() == null) {
      return Response.badRequest(body: "Not form data");
    }

    // 3. Process the Data Stream
    await for (final formData in request.formData()!.formData) {
      // We only care about the file part
      if (formData.filename != null) {
        final String filename = formData.filename!;
        final File file = File('${downloadsDir.path}/$filename');

        print("Receiving file: ${file.path}");

        // Write the stream directly to disk (Low memory usage)
        final sink = file.openWrite();
        await formData.part.pipe(sink); // Pipes bytes from Network -> Disk
        await sink.close();
      }
    }

    return Response.ok("Upload Complete");
  }

  @override
  void stop() {
    _server?.close();
    _server = null;
  }
}

class MobileFileTransferRepository implements _FileTransferServerRepository {
  // Singleton
  MobileFileTransferRepository._internal();
  static final MobileFileTransferRepository instance =
      MobileFileTransferRepository._internal();

  HttpServer? _server;
  static const int _port = 8080;

  @override
  Future<void> start() async {
    if (_server != null) return;

    // 1. Permission Check (Crucial for reading metadata)
    if (Platform.isAndroid) {
      if (!await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    }

    // 2. Define Route
    final app = Router();

    // API: GET /browse?path=/storage/emulated/0
    app.get('/browse', _handleBrowseRequest);

    final staticHandler = createStaticHandler(
      '/storage/emulated/0',
      listDirectories: false,
      useHeaderBytesForContentType: true, // Auto-detects if it's an image/video
    );

    app.get('/download', _handleDownloadRequest);

    // Mount it at '/files/'
    // Access: http://<IP>:8080/files/DCIM/Camera/photo.jpg
    app.mount('/files/', staticHandler);

    // 3. Start Server
    try {
      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addHandler(app.call);

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
      print('Metadata Server running on port ${_server!.port}');
    } catch (e) {
      print("Failed to start Metadata Server: $e");
    }
  }

  @override
  Future<void> stop() async {
    if (_server != null) {
      print("Stopping Metadata Server...");
      await _server!.close();
      _server = null;
    }
  }

  // --- Handlers ---

  Future<Response> _handleDownloadRequest(Request request) async {
    // 1. Parse 'paths' parameter (shelf handles ?paths=a&paths=b as a List<String>)
    final queryParams = request.url.queryParametersAll;
    final List<String>? paths = queryParams['paths'];

    if (paths == null || paths.isEmpty) {
      return Response.badRequest(body: "No paths provided");
    }

    // --- SCENARIO A: Single File Download ---
    if (paths.length == 1) {
      final file = File(paths.first);
      if (!file.existsSync()) return Response.notFound("File not found");

      // Check if it's a directory (Folder download needs zipping)
      if (await FileSystemEntity.isDirectory(paths.first)) {
        return _streamZip(paths); // Zip the single folder
      }

      // Serve the single file directly with "attachment" disposition to force download
      return Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Disposition':
              'attachment; filename="${paths.first.split('/').last}"',
          'Content-Length': file.lengthSync().toString(),
        },
      );
    }

    // --- SCENARIO B: Multiple Files (Zip them) ---
    return _streamZip(paths);
  }

  /// Helper to zip list of files/folders and stream the result
  Future<Response> _streamZip(List<String> paths) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final zipFileName =
          "download_${DateTime.now().millisecondsSinceEpoch}.zip";
      final zipFilePath = "${tempDir.path}/$zipFileName";

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);

      for (String path in paths) {
        if (await FileSystemEntity.isDirectory(path)) {
          encoder.addDirectory(Directory(path));
        } else if (await FileSystemEntity.isFile(path)) {
          encoder.addFile(File(path));
        }
      }
      encoder.close();

      final zipFile = File(zipFilePath);

      return Response.ok(
        zipFile.openRead(),
        headers: {
          'Content-Type': 'application/zip',
          'Content-Disposition': 'attachment; filename="$zipFileName"',
          'Content-Length': zipFile.lengthSync().toString(),
        },
      );
    } catch (e) {
      return Response.internalServerError(body: "Zipping failed: $e");
    }
  }

  Future<Response> _handleBrowseRequest(Request request) async {
    // 1. Get Path
    // Default to Root if no path provided
    final String rootPath = "/storage/emulated/0";
    final String path = request.url.queryParameters['path'] ?? rootPath;

    final dir = Directory(path);

    // 2. Validate
    if (!dir.existsSync()) {
      return Response.notFound(jsonEncode({"error": "Directory not found"}));
    }

    try {
      // 3. Fetch Metadata
      final List<Map<String, dynamic>> fileList = dir.listSync().map((entity) {
        final isDir = entity is Directory;
        return {
          "name": entity.path.split('/').last,
          "path": entity.path,
          "isDir": isDir,
          "size": (entity is File) ? entity.lengthSync() : 0,
          "lastModified": (entity is File)
              ? entity.lastModifiedSync().toIso8601String()
              : null,
        };
      }).toList();

      // 4. Return JSON
      return Response.ok(
        jsonEncode({"currentPath": path, "files": fileList}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({"error": "Access Denied: $e"}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
