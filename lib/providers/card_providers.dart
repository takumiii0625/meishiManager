// ============================================================
// card_providers.dart
// Riverpodのプロバイダーをまとめたファイル
//
// 【Riverpodとは？】
//   アプリ全体で状態（データ）を管理・共有するライブラリ。
//   画面から ref.watch(xxxProvider) と書くだけでデータを取得できる。
//
// 【Providerの種類】
//   Provider        = 変化しない値・インスタンスを提供する
//   StreamProvider  = Firestoreのリアルタイム監視に使う
//   FutureProvider  = 非同期処理（追加・更新・削除など）に使う
//   StateNotifier   = 複数の状態をまとめて管理する
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../repositories/card_repository.dart';
import '../services/gemini_service.dart';
import '../services/business_card_service.dart';
import 'auth_providers.dart';

// ============================================================
// インフラ層のProvider
// ============================================================

/// Firestoreインスタンスを提供するProvider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// CardRepositoryを提供するProvider
final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(firestoreProvider));
});

/// GeminiServiceを提供するProvider
/// ★ 以前は BatchAnalyzePage で直接 GeminiService() と new していたが、
///   Provider経由にすることで、テストや差し替えが容易になる
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// BusinessCardServiceを提供するProvider
/// ★ 以前は BatchAnalyzePage で直接 BusinessCardService() と new していたが、
///   Provider経由にすることで、依存関係が明確になる
final businessCardServiceProvider = Provider<BusinessCardService>((ref) {
  return BusinessCardService();
});

// ============================================================
// Firestoreデータ取得のProvider
// ============================================================

/// 通常の名刺一覧（isDeleted=false）をリアルタイム監視するProvider
/// ref.watch(cardsStreamProvider) で画面から使う
final cardsStreamProvider = StreamProvider<List<CardModel>>((ref) {
  final uid = ref.watch(uidProvider);
  // uidが空の間はFirestoreに接続しない（ログイン前の事故防止）
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(cardRepositoryProvider).watchCards(uid);
});

/// ゴミ箱の名刺一覧をリアルタイム監視するProvider
final trashCardsStreamProvider = StreamProvider<List<CardModel>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(cardRepositoryProvider).watchTrashCards(uid);
});

/// 名刺1件をリアルタイム監視するProvider（詳細画面用）
/// family = 引数（cardId）を受け取れるProvider
final cardStreamProvider =
    StreamProvider.family<CardModel, String>((ref, cardId) {
  final uid = ref.watch(uidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(cardRepositoryProvider).watchCard(uid, cardId);
});

// ============================================================
// CRUD操作のProvider
// ============================================================

/// 名刺追加のパラメータクラス
class AddCardParams {
  AddCardParams({
    required this.name,
    required this.company,
    this.industry = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.frontImageUrl = '',
    this.backImageUrl = '',
    this.rawText = '',
    this.prefecture = '',
    this.department = '', // ★ 部署
    this.jobLevel = '',   // ★ 役職
    this.tags = const [],
    this.industryCandidates = const [],
  });

  final String name;
  final String company;
  final String industry;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String frontImageUrl;
  final String backImageUrl;
  final String rawText;
  final String prefecture;
  final String department; // ★ 部署
  final String jobLevel;   // ★ 役職
  final List<String> tags;
  final List<String> industryCandidates;
}

/// 名刺を新規追加するProvider
final addCardProvider =
    FutureProvider.autoDispose.family<void, AddCardParams>((ref, params) async {
  final uid = ref.read(uidProvider);
  await ref.read(cardRepositoryProvider).addCard(uid,
      name: params.name,
      company: params.company,
      industry: params.industry,
      phone: params.phone,
      email: params.email,
      address: params.address,
      notes: params.notes,
      frontImageUrl: params.frontImageUrl,
      backImageUrl: params.backImageUrl,
      rawText: params.rawText,
      prefecture: params.prefecture,
      department: params.department, // ★ 部署
      jobLevel: params.jobLevel,     // ★ 役職
      tags: params.tags,
      industryCandidates: params.industryCandidates);
});

/// 名刺更新のパラメータクラス
class UpdateCardParams {
  UpdateCardParams({
    required this.cardId,
    required this.name,
    required this.company,
    this.industry = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.frontImageUrl = '',
    this.backImageUrl = '',
    this.rawText = '',
    this.prefecture = '',
    this.department = '', // ★ 部署
    this.jobLevel = '',   // ★ 役職
    this.tags = const [],
  });

  final String cardId;
  final String name;
  final String company;
  final String industry;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String frontImageUrl;
  final String backImageUrl;
  final String rawText;
  final String prefecture;
  final String department; // ★ 部署
  final String jobLevel;   // ★ 役職
  final List<String> tags;
}

/// 名刺を更新するProvider
final updateCardProvider =
    FutureProvider.autoDispose.family<void, UpdateCardParams>((ref, params) async {
  final uid = ref.read(uidProvider);
  await ref.read(cardRepositoryProvider).updateCard(uid, params.cardId,
      name: params.name,
      company: params.company,
      industry: params.industry,
      phone: params.phone,
      email: params.email,
      address: params.address,
      notes: params.notes,
      frontImageUrl: params.frontImageUrl,
      backImageUrl: params.backImageUrl,
      rawText: params.rawText,
      prefecture: params.prefecture,
      department: params.department, // ★ 部署
      jobLevel: params.jobLevel,     // ★ 役職
      tags: params.tags);
});

/// 論理削除（ゴミ箱へ移動）するProvider
/// moveToTrashProvider(cardId) という形で使う
final moveToTrashProvider =
    FutureProvider.autoDispose.family<void, String>((ref, cardId) async {
  final uid = ref.read(uidProvider);
  await ref.read(cardRepositoryProvider).moveToTrash(uid, cardId);
});

/// ゴミ箱から復元するProvider
final restoreFromTrashProvider =
    FutureProvider.autoDispose.family<void, String>((ref, cardId) async {
  final uid = ref.read(uidProvider);
  await ref.read(cardRepositoryProvider).restoreFromTrash(uid, cardId);
});

/// 完全削除（Firestoreから物理的に削除）するProvider
final deleteCardProvider =
    FutureProvider.autoDispose.family<void, String>((ref, cardId) async {
  final uid = ref.read(uidProvider);
  await ref.read(cardRepositoryProvider).deleteCard(uid, cardId);
});

/// タグ更新のパラメータクラス
class UpdateTagsParams {
  UpdateTagsParams({required this.cardId, required this.tags});
  final String cardId;
  final List<String> tags;
}

/// タグを更新するProvider
final updateTagsProvider =
    FutureProvider.autoDispose.family<void, UpdateTagsParams>((ref, params) async {
  final uid = ref.read(uidProvider);
  await ref.read(cardRepositoryProvider)
      .updateTags(uid, params.cardId, params.tags);
});

// ============================================================
// 解析進捗のStateNotifier
// ============================================================

/// 解析・保存処理の進捗状態をまとめたクラス
///
/// 【なぜStateNotifierを使うか？】
///   以前は BatchAnalyzePage の setState で
///   _currentStep, _statusText, _isProcessing などを
///   バラバラに管理していた。
///   StateNotifier にまとめることで：
///   ・状態が一か所で管理される
///   ・Widget（画面）に依存しないので mounted チェックが不要になる
///   ・どの画面からでも状態を読める
class AnalyzeState {
  final int currentStep;   // 今何枚目を処理中
  final int totalSteps;    // 合計枚数
  final String statusText; // 画面に表示するステータス文字列
  final bool isProcessing; // 処理中フラグ（trueの間は戻るボタン無効）
  final bool isDone;       // 完了フラグ
  final String errorText;  // エラーメッセージ（空文字 = エラーなし）
  final int savedCount;    // 保存に成功した枚数

  const AnalyzeState({
    this.currentStep = 0,
    this.totalSteps = 0,
    this.statusText = '準備中...',
    this.isProcessing = false,
    this.isDone = false,
    this.errorText = '',
    this.savedCount = 0,
  });

  // 一部だけ変えたコピーを作るメソッド
  AnalyzeState copyWith({
    int? currentStep,
    int? totalSteps,
    String? statusText,
    bool? isProcessing,
    bool? isDone,
    String? errorText,
    int? savedCount,
  }) =>
      AnalyzeState(
        currentStep: currentStep ?? this.currentStep,
        totalSteps: totalSteps ?? this.totalSteps,
        statusText: statusText ?? this.statusText,
        isProcessing: isProcessing ?? this.isProcessing,
        isDone: isDone ?? this.isDone,
        errorText: errorText ?? this.errorText,
        savedCount: savedCount ?? this.savedCount,
      );
}

/// 解析進捗を管理するStateNotifier
class AnalyzeNotifier extends StateNotifier<AnalyzeState> {
  AnalyzeNotifier(this._ref) : super(const AnalyzeState());

  // 他のProviderを参照するために Ref を保持する
  final Ref _ref;

  /// メインの解析・保存処理
  ///
  /// scanResults は CardScanResult のリスト
  /// （dynamic にしているのは scan_step.dart への循環importを避けるため）
  Future<void> startAnalysis(List<dynamic> scanResults) async {
    if (state.isProcessing) return;

    state = state.copyWith(
      isProcessing: true,
      errorText: '',
      statusText: '名刺をスキャン中...',
      totalSteps: scanResults.length,
      currentStep: 0,
      savedCount: 0,
      isDone: false,
    );

    try {
      // ★ Provider経由でサービスを取得（直接 new しない）
      final geminiService = _ref.read(geminiServiceProvider);
      final cardService = _ref.read(businessCardServiceProvider);

      // 表面+裏面のペアリストを作る
      final imagePairs = scanResults.map((r) => CardImagePair(
        frontPath: r.frontImagePath as String,
        backPath: r.backImagePath as String?,
      )).toList();

      // Geminiにまとめて送って解析
      final geminiResults = await geminiService.analyzeBatch(
        imagePairs: imagePairs,
        onProgress: (current, total) {
          // StateNotifier は Widget に依存しないので mounted チェック不要
          state = state.copyWith(
            currentStep: current,
            statusText: '名刺情報を抽出しています... ($current/$total枚目)',
          );
        },
      );

      // 解析結果を1件ずつFirestoreに保存
      int savedCount = 0;
      for (int i = 0; i < scanResults.length; i++) {
        final scanResult = scanResults[i];
        final geminiResult = i < geminiResults.length
            ? geminiResults[i]
            : GeminiCardResult(rawText: '', card: {});

        state = state.copyWith(
          currentStep: i + 1,
          statusText: 'データベースに登録しています... (${i + 1}/${scanResults.length}枚目)',
        );

        await cardService.addCard(
          card: geminiResult.card,
          rawText: geminiResult.rawText,
          frontImagePath: scanResult.frontImagePath as String?,
          backImagePath: scanResult.backImagePath as String?,
        );
        savedCount++;
      }

      state = state.copyWith(
        isDone: true,
        isProcessing: false,
        savedCount: savedCount,
        statusText: '$savedCount枚の名刺を登録しました！',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorText: 'エラーが発生しました:\n$e',
        statusText: '読み取りに失敗しました',
      );
    }
  }

  /// 状態をリセット（再試行時に呼ぶ）
  void reset() => state = const AnalyzeState();
}

/// 解析進捗を提供するProvider
/// autoDispose = 画面を閉じたら状態が自動リセットされる
final analyzeProvider =
    StateNotifierProvider.autoDispose<AnalyzeNotifier, AnalyzeState>(
  (ref) => AnalyzeNotifier(ref),
);
