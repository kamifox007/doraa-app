dynamic getPlatformFile(String path) {
  return path;
}

bool fileExists(String path) {
  return false;
}

Future<int> getFileLength(dynamic file) async {
  return 0;
}

String getFilePath(dynamic file) {
  if (file is String) {
    return file;
  }
  return '';
}
