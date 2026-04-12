// lib/services/gemini_service.dart
//
// 【このファイルの役割】
//   名刺画像をGemini APIに送って、構造化JSONとして解析結果を返す。
//   1リクエストで最大10枚まとめて送れる（コスト・速度の最適化）。
//
// 【解析できる項目】
//   会社名 / 氏名 / 役職 / 電話 / メール / 住所 / 業種
//   ★ prefecture（都道府県）→ 住所から自動抽出（新規追加）
//   ★ job_level（役職レベル）→ 役職名から部長/課長/担当などに正規化（新規追加）
//   裏面対応：表面＋裏面を両方Geminiに送って解析する
//    - 裏面がない場合はスキップして表面だけ送る
//    - 1枚の名刺につき「表面画像 + (裏面画像)」で1セット
//    - Geminiへのプロンプトも「表面/裏面を合わせて解析」に変更

import 'dart:convert';
import 'dart:io'; // File型を使うため必須
import 'package:http/http.dart' as http;
import 'image_compress_service.dart';

/// 1枚分の解析結果を表すクラス
class GeminiCardResult {
  final String rawText; // OCRで読み取った生テキスト
  final Map<String, dynamic> card; // 構造化された名刺データ

  const GeminiCardResult({
    required this.rawText,
    required this.card,
  });
}

/// 1枚のスキャン情報（表面パス＋裏面パス）
class CardImagePair {
  final String frontPath;
  final String? backPath; // null = 裏面なし

  const CardImagePair({required this.frontPath, this.backPath});
}

class GeminiService {
  // dart-define で渡すAPIキー
  // 起動コマンド例: flutter run --dart-define=GEMINI_API_KEY=AIza...
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');
  static const String _geminiModel = 'gemini-2.0-flash';

  // ─────────────────────────────────────────────────────────
  // 複数枚まとめて解析（表面＋裏面セットで送る）
  //
  // [引数]
  //   imagePairs : 表面+裏面のペアリスト（裏面はnullでもOK）
  //   onProgress : 「今何枚目を処理中か」をUIに通知するコールバック
  //                例: onProgress(2, 5) → 「5枚中2枚目」
  // ─────────────────────────────────────────────────────────
  Future<List<GeminiCardResult>> analyzeBatch({
    required List<CardImagePair> imagePairs,
    void Function(int current, int total)? onProgress,
  }) async {
    if (_geminiApiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEYが設定されていません。\n'
        '起動時に --dart-define=GEMINI_API_KEY=xxx を指定してください。',
      );
    }
    if (imagePairs.isEmpty) return [];

    // 10枚ずつに分割して処理（Geminiの制限対策）
    // 例: 15枚 → [10枚, 5枚] の2リクエスト
    // 根拠: inline_base64上限20MB / 出力8192tokens に対して
    //       名刺10枚 = 約1MB・5,500tokens で安全圏内
    const batchSize = 10;
    final results = <GeminiCardResult>[];
    int processed = 0;

    for (int i = 0; i < imagePairs.length; i += batchSize) {
      final chunk = imagePairs.sublist(
        i,
        (i + batchSize).clamp(0, imagePairs.length),
      );

      // UIに進捗を通知
      onProgress?.call(processed + 1, imagePairs.length);

      final chunkResults = await _analyzeChunk(chunk);
      results.addAll(chunkResults);
      processed += chunk.length;

      // 最終チャンク以外は少し待つ（レートリミット対策）
      // 10枚バッチに増やしたのでリスク対策として1000msに延長
      if (i + batchSize < imagePairs.length) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    return results;
  }

  // ─────────────────────────────────────────────────────────
  // 後方互換用：表面パスのリストだけで呼べる旧インターフェース
  // batch_analyze_page.dart などからの呼び出しを壊さないために残す
  // ─────────────────────────────────────────────────────────
  Future<List<GeminiCardResult>> analyzeBatchFromPaths({
    required List<String> imagePaths,
    void Function(int current, int total)? onProgress,
  }) {
    return analyzeBatch(
      imagePairs: imagePaths.map((p) => CardImagePair(frontPath: p)).toList(),
      onProgress: onProgress,
    );
  }

  // ─────────────────────────────────────────────────────────
  // 1チャンク（最大5枚）を解析する内部メソッド
  //
  // 【裏面対応の仕組み】
  //   1枚の名刺につき、表面→裏面の順で画像をリクエストに追加する。
  //   プロンプトで「画像ペア」として説明し、両面の情報を統合するよう指示。
  //   裏面がない場合はその枚の裏面画像をスキップする。
  // ─────────────────────────────────────────────────────────
  Future<List<GeminiCardResult>> _analyzeChunk(
      List<CardImagePair> pairs) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_geminiModel:generateContent?key=$_geminiApiKey',
    );

    // 各名刺の画像データ（表面 + 裏面）をbase64に変換
    // imageMeta[i] = { 'hasBack': bool, 'frontIndex': int, 'backIndex': int? }
    final imageParts = <Map<String, dynamic>>[];
    final imageMeta = <Map<String, dynamic>>[];

    // 使い終わった圧縮済み一時ファイルをまとめて追跡するリスト
    // → Geminiに送信した後にまとめて削除する
    final tempFiles = <File>[];

    int imageIndex = 1; // 画像の通し番号（1始まり）
    for (final pair in pairs) {
      final frontCompressed =
          await ImageCompressService.compressForGemini(pair.frontPath);
      tempFiles.add(frontCompressed); // 削除对象に登録
      final frontBytes = await frontCompressed.readAsBytes();
      imageParts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Encode(frontBytes),
        }
      });
      final frontIdx = imageIndex++;

      int? backIdx;
      if (pair.backPath != null && pair.backPath!.isNotEmpty) {
        // 裏面がある場合のみ追加
        final backCompressed =
            await ImageCompressService.compressForGemini(pair.backPath!);
        tempFiles.add(backCompressed); // 削除对象に登録
        final backBytes = await backCompressed.readAsBytes();
        imageParts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Encode(backBytes),
          }
        });
        backIdx = imageIndex++;
      }

      imageMeta.add({
        'hasBack': backIdx != null,
        'frontIndex': frontIdx,
        'backIndex': backIdx,
      });
    }

    final count = pairs.length;

    // 各名刺の画像説明を作成（「名刺1: 画像1(表面) 画像2(裏面)」など）
    final cardDesc = imageMeta.asMap().entries.map((e) {
      final i = e.key + 1;
      final meta = e.value;
      final front = '画像${meta['frontIndex']}（表面）';
      final back =
          meta['hasBack'] ? '+ 画像${meta['backIndex']}（裏面）' : '（裏面なし）';
      return '名刺$i: $front $back';
    }).join('\n');

    // ─────────────────────────────────────────────────────
    // Geminiへのプロンプト（裏面対応版）
    //
    // 【ポイント】
    //   prefecture : 住所から都道府県だけを抽出（例: "東京都"）
    //   job_level  : 役職名を正規化（例: "営業部長" → "部長"）
    //   - 表面と裏面は「同じ名刺の両面」として合わせて解析する
    //   - 裏面にある電話・メール・住所なども抽出対象
    //   - 裏面がない場合は表面だけで解析
    //
    // 【なぜ prefecture を別フィールドにするか？】
    //   address に「東京都渋谷区...」と入っていても、
    //   都道府県だけで絞り込みたい場合に毎回パースするのは大変。
    //   Geminiに最初から抽出させることで保存・検索が楽になる。
    // ─────────────────────────────────────────────────────────
    final prompt = '''
あなたは名刺OCRの専門家です。
以下の名刺$count枚を解析してください。各名刺は表面と裏面の画像で構成されます。

名刺と画像の対応:
$cardDesc

各名刺を個別に解析し、必ず「JSONのみ」を返してください。
説明文・```・前後の文章は一切禁止です。

【重要】表面と裏面がある場合は、両面の情報を統合して1つのデータにしてください。
例: 表面に氏名・会社名、裏面に英語表記・QRコード・URLがある場合 → 全て1つのJSONにまとめる

返すJSONのスキーマ（厳守）:
{
  "cards": [
    {
      "card_index": 1,
      "text": "表面と裏面から読み取れた全文テキスト（改行あり）",
      "card": {
        "company": "会社名",
        "department": "部署名",
        "title": "役職名（名刺に記載された原文のまま）",
        "name_ja": "氏名（日本語）",
        "name_en": "氏名（英語）",
        "phone": ["電話番号1", "電話番号2"],
        "email": ["メール1"],
        "url": ["URL1"],
        "postal_code": "郵便番号（ハイフンなし数字7桁）",
        "address": "住所（都道府県から番地まで全文）",
        "prefecture": "都道府県のみ（例: 東京都、大阪府、愛知県）",
        "others": ["その他の情報"],
        "industry": "推定した業種（例: IT・ソフトウェア、製造業、金融・保険、医療・福祉、教育、小売・流通、建設・不動産、コンサルティング、メディア・広告、その他）",
        "industry_candidates": [
          {"label": "業種名", "confidence": 0.9}
        ]
      }
    }
  ]
}

ルール:
- 読み取れない項目は空文字または空配列にする（nullにしない）
- phone / email / url / others は配列で返す
- 表面と裏面に同じ情報があれば重複して入れない
- prefecture は address から都道府県部分だけを抜き出す
  例: 住所が「東京都渋谷区...」なら prefecture は「東京都」
  例: 住所が「大阪府大阪市...」なら prefecture は「大阪府」
  例: 住所が読み取れない場合は空文字
- industry は会社名・部署・役職などから推定する
- industry_candidates は確信度が高い順に最大3件
- confidence は 0.0〜1.0 の数値
- card_index は名刺の番号（1始まり）
- cards は必ず$count件返す
''';

    // リクエストボディ組み立て
    // テキストプロンプト → 画像1 → 画像2 → ... の順で渡す
    final parts = <Map<String, dynamic>>[
      {'text': prompt},
      ...imageParts,
    ];

    final body = {
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': 0.1,   // 低いほど安定した出力になる
        'topP': 0.9,
        'maxOutputTokens': 8192, // 10枚×裏面ありで最大~4500tokens → 8192で安全圏
      }
    };

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90)); // 90秒でタイムアウト（10枚バッチ対応）

    // ── Geminiに送信済み→一時ファイルをまとめて削除 ───────────────
    // エラー時も必ず削除する（リークしないように tryの外で削除）
    await ImageCompressService.deleteTempAll(tempFiles);

    if (res.statusCode != 200) {
      throw Exception('Gemini APIエラー: ${res.statusCode}\n${res.body}');
    }

    final decoded = jsonDecode(res.body);
    final outText =
        decoded['candidates'][0]['content']['parts'][0]['text'] as String;

    // Geminiが```json ... ```で返してきた場合にも対応
    // { から } までの部分だけを取り出す
    final start = outText.indexOf('{');
    final end = outText.lastIndexOf('}') + 1;
    if (start == -1 || end == 0) {
      throw Exception('GeminiのレスポンスからJSONを取得できませんでした:\n$outText');
    }

    final jsonStr = outText.substring(start, end);
    final outJson = jsonDecode(jsonStr) as Map<String, dynamic>;

    // card_index と image_index の両方に対応（互換性のため）
    final cardsRaw = outJson['cards'] as List? ?? [];

    return cardsRaw.map((item) {
      final cardData = Map<String, dynamic>.from(item['card'] ?? {});
      return GeminiCardResult(
        rawText: (item['text'] ?? '') as String,
        card: cardData,
      );
    }).toList();
  }
}
