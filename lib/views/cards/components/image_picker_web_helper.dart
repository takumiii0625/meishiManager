// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Web専用：dart:htmlを使ってファイルを選択する
Future<({Uint8List bytes, String name})?> pickImageFromWeb() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..click();

  await input.onChange.first;
  if (input.files == null || input.files!.isEmpty) return null;

  final file = input.files!.first;
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;

  return (
    bytes: Uint8List.fromList(reader.result as List<int>),
    name: file.name,
  );
}
