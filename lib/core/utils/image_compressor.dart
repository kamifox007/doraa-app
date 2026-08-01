import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'file_utils.dart';

class ImageCompressor {
  static Future<dynamic> compress(dynamic file, {int quality = 85}) async {
    if (kIsWeb) return file;
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = getFilePath(file);

    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      targetPath,
      quality: quality,
      minWidth: 1024,
      minHeight: 1024,
      format: CompressFormat.jpeg,
    );

    return getPlatformFile(result!.path);
  }
}
