import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gemini API呼び出し結果の型
class _GeminiCardResult {
  final String text;
  final Map<String, dynamic> card;
  final Map<String, dynamic>? corners;
  const _GeminiCardResult({required this.text, required this.card, this.corners});
}

typedef OnCapturedCallback = Future<void> Function(
  Map<String, dynamic> card,
  String rawText,
  String? imagePath,
);

class OcrScanPage extends StatefulWidget {
  const OcrScanPage({super.key, this.onCaptured});
  final OnCapturedCallback? onCaptured;

  @override
  State<OcrScanPage> createState() => _OcrScanPageState();
}

class _OcrScanPageState extends State<OcrScanPage> {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _geminiModel = 'gemini-2.0-flash';

  bool _busy = false;
  XFile? _lastShot;
  String _plainText = '';
  Map<String, dynamic>? _cardJson;
  String _error = '';


@override
void initState() {
  super.initState();
  // ✅ 画面が表示されたら、0.5秒後（描画完了後）に自動でカメラを起動する
  Future.delayed(const Duration(milliseconds: 500), () {
    if (mounted) {
      _captureAndOcr();
    }
  });
}

  /// 撮影 → Gemini OCR
  Future<void> _captureAndOcr() async {
    if (_busy) return;

    try {
      final directory = await getTemporaryDirectory();
      final String croppedPath = p.join(
        directory.path,
        "${DateTime.now().millisecondsSinceEpoch}_cropped.jpg",
      );

      bool success = await EdgeDetection.detectEdge(
        croppedPath,
        canUseGallery: true,
        androidCropTitle: '名刺のスキャン',
        androidCropReset: 'リセット',
      );

      if (!success) return;

      setState(() {
        _busy = true;
        _error = '';
      });

      final bytes = await File(croppedPath).readAsBytes();
      final b64 = base64Encode(bytes);

      // Geminiへ解析依頼
      final geminiResult = await _callGeminiBusinessCard(base64Jpeg: b64);

      // Firebaseへアップロード
      _uploadToFirebase(bytes);

      if (!mounted) return;
      setState(() {
        _lastShot = XFile(croppedPath);
        _plainText = geminiResult.text;
        _cardJson = geminiResult.card;
      });
    } catch (e) {
      setState(() => _error = 'スキャンまたは解析に失敗: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadToFirebase(Uint8List bytes) async {
  try {
    final fileName = "scanned_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final storageRef = FirebaseStorage.instance.ref().child("business_cards/$fileName");
    // Uint8Listであれば、putDataがそのまま受け取れます
    await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
  } catch (e) {
    debugPrint("Firebase保存失敗: $e");
  }
}

  /// 保存して次へ（連続撮影ループ）
  Future<void> _saveAndNext() async {
    if (_busy) return;
    if (_plainText.isEmpty && _cardJson == null) return;

    try {
      setState(() => _busy = true);
      final card = _cardJson ?? {};
      final text = _plainText;
      final imagePath = _lastShot?.path;

      if (widget.onCaptured != null) {
        await widget.onCaptured!(card, text, imagePath);

        if (!mounted) return;

        setState(() {
          _plainText = '';
          _cardJson = null;
          _lastShot = null;
          _busy = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました。次を撮影します'), duration: Duration(milliseconds: 1000)),
        );

        // ✅ 保存後すぐに次の撮影を開始
        _captureAndOcr();
        return;
      }
      Navigator.pop(context, {"card": card, "text": text, "imagePath": imagePath});
    } catch (e) {
      setState(() => _error = '保存失敗: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// プロンプトを完全に復元したGemini呼び出し
  Future<_GeminiCardResult> _callGeminiBusinessCard({required String base64Jpeg}) async {
    if (_geminiApiKey.isEmpty) throw Exception('APIキーが設定されていません。');

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey',
    );

    final prompt = '''
あなたは名刺OCRの抽出器です。
次の画像は「名刺」です。日本語（漢字/かな/英数字）をできるだけ正確に読み取ってください。

必ず「JSONのみ」を返してください（説明文、```、前後の文章は禁止）。
JSONのスキーマはこれに厳密に従ってください:

{
  "text": "画像から読み取れた全文テキスト（改行あり）",
  "card": {
    "company": "",
    "department": "",
    "title": "",
    "name_ja": "",
    "name_en": "",
    "phone": [],
    "email": [],
    "url": [],
    "postal_code": "",
    "address": "",
    "others": []
  }
}

ルール:
- 読み取れない項目は空文字 or 空配列
- phone/email/url は配列
- text には全文を入れる
- card には名刺として使える形に整理して入れる
''';

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {"inline_data": {"mime_type": "image/jpeg", "data": base64Jpeg}}
          ]
        }
      ],
      "generationConfig": {"temperature": 0.1, "topP": 0.9, "maxOutputTokens": 2048}
    };

    final res = await http.post(uri, headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
    if (res.statusCode != 200) throw Exception('Gemini API error: ${res.statusCode}');

    final decoded = jsonDecode(res.body);
    final outText = decoded['candidates'][0]['content']['parts'][0]['text'] as String;

    // JSON部分のみ抽出
    final start = outText.indexOf('{');
    final end = outText.lastIndexOf('}') + 1;
    final jsonStr = outText.substring(start, end);
    final outJson = jsonDecode(jsonStr);

    return _GeminiCardResult(
      text: (outJson['text'] ?? '') as String,
      card: Map<String, dynamic>.from(outJson['card'] ?? {}),
      corners: outJson['corners'] as Map<String, dynamic>?,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('名刺スキャン')),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _lastShot != null
                  ? Image.file(File(_lastShot!.path), fit: BoxFit.contain)
                  : const SizedBox.shrink(),
            ),
          ),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    final hasResult = _plainText.isNotEmpty || _cardJson != null;
    return Container(
      height: MediaQuery.of(context).size.height * 0.42,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red, fontSize: 12)),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                hasResult ? "【解析結果】\n${const JsonEncoder.withIndent('  ').convert(_cardJson)}" : 'ここに結果が表示されます',
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontFamily: 'monospace'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _busy ? null : () => setState(() => _lastShot = null), child: const Text('クリア'))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(onPressed: (hasResult && !_busy) ? _saveAndNext : null, icon: const Icon(Icons.save), label: const Text('保存して次へ'))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _busy ? null : _captureAndOcr, icon: const Icon(Icons.camera_alt), label: const Text('撮影してOCR'))),
        ],
      ),
    );
  }
}