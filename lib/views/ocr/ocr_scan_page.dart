// lib/views/ocr/ocr_scan_page.dart
//
// ------------------------------------------------------------
// 名刺OCRスキャン画面（撮影 → GeminiでJSON化）
// ------------------------------------------------------------
// ✅ この画面でやること
// 1) カメラを表示（横伸びしない / 上に寄せる）
// 2) ボタンで静止画を撮影
// 3) 撮影画像を Gemini API に送って「名刺JSON + 全文テキスト」を取得
// 4) 結果を画面下に表示
// 5) 「保存して次へ（連続）」または「この結果を確定（単発）」が押せる
//
// ✅ 重要（キーの渡し方）
// flutter run --dart-define=GEMINI_API_KEY=あなたのキー
// ------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

/// Gemini API呼び出し結果の「型」
class _GeminiCardResult {
  final String text; // 画像から読めた全文
  final Map<String, dynamic> card; // 整形した名刺情報

  const _GeminiCardResult({
    required this.text,
    required this.card,
  });
}

/// 「保存して次へ」が押された時に、上位画面へ結果を渡すコールバック
typedef OnCapturedCallback = Future<void> Function(
  Map<String, dynamic> card,
  String rawText,
  String? imagePath,
);

class OcrScanPage extends StatefulWidget {
  const OcrScanPage({
    super.key,
    this.onCaptured, // 渡されなければ単発モード
  });

  final OnCapturedCallback? onCaptured;

  @override
  State<OcrScanPage> createState() => _OcrScanPageState();
}

class _OcrScanPageState extends State<OcrScanPage> {
  // Gemini API Key（dart-define）
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  // 使用モデル
  static const String _geminiModel = 'gemini-2.0-flash';

  // Camera
  CameraController? _controller;
  bool _initializing = true;

  // UI State
  bool _busy = false;
  XFile? _lastShot;
  String _plainText = '';
  Map<String, dynamic>? _cardJson;
  String _error = '';

  // ガイド枠（名刺は横長が多い）
  final double _frameWidthFactor = 0.96;
  final double _frameAspect = 1.70;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// カメラ初期化
  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = '';
    });

    // 1) カメラ権限
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'カメラ権限が必要です（設定から許可してください）';
      });
      return;
    }

    // 2) 背面カメラを探す
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // 3) コントローラ作成
    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await controller.initialize();

    // ピント/露出オート（未対応端末があるのでtry/catch）
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _controller = controller;
      _initializing = false;
    });
  }

  /// 撮影 → Gemini OCR
  Future<void> _captureAndOcr() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = '';
      _plainText = '';
      _cardJson = null;
    });

    try {
      // 撮影前にAF/AEを走らせる
      try {
        await c.setFocusMode(FocusMode.auto);
        await c.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      // 撮影
      final shot = await c.takePicture();
      _lastShot = shot;

      // 画像→base64
      final bytes = await File(shot.path).readAsBytes();
      final b64 = base64Encode(bytes);

      // Gemini呼び出し
      final result = await _callGeminiBusinessCard(base64Jpeg: b64);

      if (!mounted) return;
      setState(() {
        _plainText = result.text;
        _cardJson = result.card;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '撮影/解析に失敗しました: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  /// 保存して次へ（連続）/ 確定（単発）
  Future<void> _saveAndNext() async {
    if (_busy) return;

    final hasResult = _plainText.trim().isNotEmpty || _cardJson != null;
    if (!hasResult) {
      setState(() => _error = '先に「撮影してOCR」を実行してください');
      return;
    }

    setState(() {
      _busy = true;
      _error = '';
    });

    try {
      final card = _cardJson ?? <String, dynamic>{};
      final text = _plainText;
      final imagePath = _lastShot?.path;

      // 連続モード：上位に保存を任せる
      if (widget.onCaptured != null) {
        await widget.onCaptured!(card, text, imagePath);
        if (!mounted) return;

        // 次の撮影に備えてリセット
        setState(() {
          _plainText = '';
          _cardJson = null;
          _lastShot = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました。次の名刺を撮影してください')),
        );
        return;
      }

      // 単発モード：結果を返して閉じる
      if (!mounted) return;
      Navigator.pop(context, {
        "card": card,
        "text": text,
        "imagePath": imagePath,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '保存に失敗: $e');
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  /// Geminiへ「名刺画像 → JSON」を依頼
  Future<_GeminiCardResult> _callGeminiBusinessCard({
    required String base64Jpeg,
  }) async {
    if (_geminiApiKey.isEmpty) {
      throw Exception(
        'Gemini APIキーが空です。\n'
        'flutter run に --dart-define=GEMINI_API_KEY=... を付けてください。',
      );
    }

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
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Jpeg,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.1,
        "topP": 0.9,
        "maxOutputTokens": 2048
      }
    };

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Gemini API error: ${res.statusCode}\n${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = (decoded['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) {
      throw Exception('Geminiの返答が空です（candidatesが空）');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = (content?['parts'] as List?) ?? const [];
    final outText = (parts.isNotEmpty ? parts.first['text'] : null) as String?;

    if (outText == null || outText.trim().isEmpty) {
      throw Exception('Geminiの返答テキストが空です');
    }

    final cleaned = _extractFirstJsonObject(outText);
    final outJson = jsonDecode(cleaned) as Map<String, dynamic>;

    final text = (outJson['text'] ?? '') as String;
    final card = (outJson['card'] is Map)
        ? (outJson['card'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    return _GeminiCardResult(text: text, card: card);
  }

  /// Geminiの出力から「最初の { ... }」を抜き出す
  String _extractFirstJsonObject(String s) {
    var t = s.trim();
    t = t.replaceAll('```json', '').replaceAll('```', '').trim();

    final start = t.indexOf('{');
    if (start < 0) throw Exception('JSONの開始 { が見つかりません');

    var depth = 0;
    for (var i = start; i < t.length; i++) {
      final ch = t[i];
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      if (depth == 0) {
        return t.substring(start, i + 1);
      }
    }
    throw Exception('JSONの終了 } が見つかりません');
  }

  /// プレビュー（位置が下がる問題対策：CenterではなくTopに寄せる）
  Widget _buildPreview(CameraController c) {
    return Align(
      alignment: Alignment.topCenter, // ✅ ここが重要
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(c),

            // 上部案内
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '名刺を枠に大きく収めて、ピントが合ってから\n「撮影してOCR」を押してください',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.25),
                  ),
                ),
              ),
            ),

            // 中央の白枠（ガイド）
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: _frameWidthFactor,
                child: AspectRatio(
                  aspectRatio: _frameAspect,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ),
            ),

            // 処理中オーバーレイ
            if (_busy)
              Container(
                color: Colors.black.withOpacity(0.25),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('解析中...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 下部結果パネル（スクロール可）
  Widget _buildBottomPanel(BuildContext context) {
    final hasResult = _plainText.trim().isNotEmpty || _cardJson != null;

    final buffer = StringBuffer();
    if (_cardJson != null) {
      buffer.writeln('--- card(JSON) ---');
      buffer.writeln(const JsonEncoder.withIndent('  ').convert(_cardJson));
      buffer.writeln('');
    }
    if (_plainText.trim().isNotEmpty) {
      buffer.writeln('--- text(全文) ---');
      buffer.writeln(_plainText.trim());
    }

    final displayText = hasResult ? buffer.toString() : 'ここにOCR結果が表示されます';

    final h = MediaQuery.of(context).size.height;
    final panelHeight = (h * 0.34).clamp(220.0, 340.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          height: panelHeight,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.98),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                spreadRadius: 1,
                offset: Offset(0, 4),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),

              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasResult ? Colors.black87 : Colors.black45,
                      height: 1.35,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _plainText = '';
                                _cardJson = null;
                                _error = '';
                                _lastShot = null;
                              });
                            },
                      child: const Text('撮り直し'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_busy || !hasResult) ? null : _saveAndNext,
                      icon: const Icon(Icons.save),
                      label: Text(widget.onCaptured != null ? '保存して次へ' : 'この結果を確定'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _captureAndOcr,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('撮影してOCR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.onCaptured != null ? 'OCRスキャン（連続）' : 'OCRスキャン'),
        actions: [
          IconButton(
            onPressed: _busy
                ? null
                : () async {
                    await _controller?.dispose();
                    _controller = null;
                    await _initCamera();
                  },
            icon: const Icon(Icons.refresh),
            tooltip: 'カメラ再起動',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: Colors.black),

          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: _initializing
                  ? const Center(child: CircularProgressIndicator())
                  : (c == null || !c.value.isInitialized)
                      ? Center(
                          child: Text(
                            _error.isNotEmpty ? _error : 'カメラを起動できませんでした',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _buildPreview(c),
            ),
          ),

          _buildBottomPanel(context),
        ],
      ),
    );
  }
}
