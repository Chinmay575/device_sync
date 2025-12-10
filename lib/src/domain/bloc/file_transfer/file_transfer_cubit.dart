import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:connect/src/data/models/browse_res.dart';
import 'package:connect/src/domain/repositories/network_repository.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

part 'file_transfer_state.dart';

class FileTransferCubit extends Cubit<FileTransferState> {
  NetworkRepository networkRepository = .instance;

  FileTransferCubit({required String baseUrl}) : super(FileTransferState()) {
    emit(state.copyWith(baseUrl: baseUrl, currentPath: "/storage/emulated/0"));
  }

  Future<void> browse() async {
    emit(state.copyWith(isLoading: true));
    try {
      String query = "?path=${state.currentPath}";
      if (state.currentPath.isEmpty) {
        query = "/storage/emulated/0";
      }
      Map<String, dynamic> res = await networkRepository.get(
        "${state.baseUrl}:8080/browse$query",
      );

      BrowseRes browseRes = BrowseRes.fromJson(res);

      emit(
        state.copyWith(
          files: browseRes.files,
          currentPath: browseRes.currentPath,
          isLoading: false,
        ),
      );
    } on Exception catch (e) {
      print(e);
    }
    emit(state.copyWith(isLoading: false));
  }

  void clearSelection() => emit(state.copyWith(selectedFiles: []));

  updateCurrentDirectory(String path) async {
    emit(state.copyWith(currentPath: path, selectedFiles: []));
    await browse();
  }

  onToggleSelect(FileElement f) {
    List<FileElement> selected = List.from(state.selectedFiles, growable: true);

    if (selected.contains(f)) {
      selected.remove(f);
    } else {
      selected.add(f);
    }

    emit(state.copyWith(selectedFiles: selected));
  }

  onSelectAll() {
    emit(state.copyWith(selectedFiles: state.files));
  }

  Future<void> downloadFiles(String serverIp, List<String> filePaths) async {
    var dio = Dio();
    // 1. Build Query Parameters
    String queryString = filePaths
        .map((p) => "paths=${Uri.encodeComponent(p)}")
        .join("&");
    String url = "http://$serverIp:8080/download?$queryString";

    // 2. Determine default filename
    String defaultFileName = (filePaths.length == 1)
        ? filePaths.first.split('/').last
        : "bundle.zip";

    String? savePath;

    // 3. Platform Specific Logic
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // --- DESKTOP: Ask User ---
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save file to...',
        fileName: defaultFileName,
      );

      if (savePath == null) {
        print("User canceled the download.");
        return;
      }
    } else {
      // --- MOBILE: Default to Downloads Folder ---
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      // Create directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      savePath = "${downloadDir.path}/$defaultFileName";
    }

    // 4. Download
    try {
      print("Downloading to: $savePath");
      await dio.download(url, savePath);
      print("Download completed!");
    } catch (e) {
      print("Download failed: $e");
    }
  }
}
