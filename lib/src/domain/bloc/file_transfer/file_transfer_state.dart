part of 'file_transfer_cubit.dart';

class FileTransferState extends Equatable {
  final String baseUrl;
  final String currentPath;
  final bool isLoading;
  final List<FileElement> files;
  final List<FileElement> selectedFiles;

  @override
  List<Object?> get props => [
    baseUrl,
    currentPath,
    isLoading,
    files,
    selectedFiles,
  ];

  FileTransferState copyWith({
    String? baseUrl,
    String? currentPath,
    bool? isLoading,
    List<FileElement>? files,
    List<FileElement>? selectedFiles,
  }) {
    return FileTransferState(
      baseUrl: baseUrl ?? this.baseUrl,
      currentPath: currentPath ?? this.currentPath,
      isLoading: isLoading ?? this.isLoading,
      files: files ?? this.files,
      selectedFiles: selectedFiles ?? this.selectedFiles,
    );
  }

  const FileTransferState({
    this.baseUrl = '',
    this.currentPath = '',
    this.isLoading = false,
    this.files = const [],
    this.selectedFiles = const [],
  });
}
