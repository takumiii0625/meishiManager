// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web専用：CSVをダウンロードする
void downloadCsvOnWeb(String csvContent, String fileName) {
  final blob = html.Blob([csvContent], 'text/csv', 'native');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
