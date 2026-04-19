import 'dart:typed_data';

/// モバイル用スタブ（dart:htmlは使わない）
Future<({Uint8List bytes, String name})?> pickImageFromWeb() async {
  // モバイルではこの関数は呼ばれない
  return null;
}
