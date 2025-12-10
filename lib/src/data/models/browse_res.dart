import 'package:equatable/equatable.dart';

class BrowseRes extends Equatable {
  const BrowseRes({required this.currentPath, required this.files});

  final String? currentPath;
  final List<FileElement> files;

  factory BrowseRes.fromJson(Map<String, dynamic> json) {
    return BrowseRes(
      currentPath: json["currentPath"],
      files: json["files"] == null
          ? []
          : List<FileElement>.from(
              json["files"]!.map((x) => FileElement.fromJson(x)),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "currentPath": currentPath,
    "files": files.map((x) => x.toJson()).toList(),
  };

  @override
  List<Object?> get props => [currentPath, files];
}

class FileElement extends Equatable {
  const FileElement({
    required this.name,
    required this.path,
    required this.isDir,
    required this.size,
    required this.lastModified,
  });

  final String? name;
  final String? path;
  final bool? isDir;
  final num? size;
  final dynamic lastModified;

  factory FileElement.fromJson(Map<String, dynamic> json) {
    return FileElement(
      name: json["name"],
      path: json["path"],
      isDir: json["isDir"],
      size: json["size"],
      lastModified: json["lastModified"],
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "path": path,
    "isDir": isDir,
    "size": size,
    "lastModified": lastModified,
  };

  @override
  List<Object?> get props => [name, path, isDir, size, lastModified];
}

/*
{
	"currentPath": "/storage/emulated/0",
	"files": [
		{
			"name": "Android",
			"path": "/storage/emulated/0/Android",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Music",
			"path": "/storage/emulated/0/Music",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Podcasts",
			"path": "/storage/emulated/0/Podcasts",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Ringtones",
			"path": "/storage/emulated/0/Ringtones",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Alarms",
			"path": "/storage/emulated/0/Alarms",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Notifications",
			"path": "/storage/emulated/0/Notifications",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Pictures",
			"path": "/storage/emulated/0/Pictures",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Movies",
			"path": "/storage/emulated/0/Movies",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Download",
			"path": "/storage/emulated/0/Download",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "DCIM",
			"path": "/storage/emulated/0/DCIM",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Documents",
			"path": "/storage/emulated/0/Documents",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Audiobooks",
			"path": "/storage/emulated/0/Audiobooks",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "Recordings",
			"path": "/storage/emulated/0/Recordings",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "ColorOS",
			"path": "/storage/emulated/0/ColorOS",
			"isDir": true,
			"size": 0,
			"lastModified": null
		},
		{
			"name": "blockcanary",
			"path": "/storage/emulated/0/blockcanary",
			"isDir": true,
			"size": 0,
			"lastModified": null
		}
	]
}*/
