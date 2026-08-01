import 'dart:io';

dynamic getPlatformFile(String path) {
  return File(path);
}

bool fileExists(String path) {
  return File(path).existsSync();
}

Future<int> getFileLength(dynamic file) async {
  if (file is File) {
    return file.length();
  }
  return 0;
}

String getFilePath(dynamic file) {
  if (file is File) {
    return file.path;
  }
  return '';
}
