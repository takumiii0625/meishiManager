// ============================================================
// batch_analyze_page.dart
// 解析・保存進捗画面
//
// 【役割】
//   MultiScanPage から受け取った CardScanResult リストを受け取り、
//   Gemini解析 → Storage保存 → Firestore保存 を順番に行う。
//   処理中はプログレスバーで進捗を表示する。
//
// 【状態管理】
//   analyzeProvider（StateNotifier）で進捗状態を管理する。
//   以前は StatefulWidget + setState でバラバラに管理していたが、
//   Riverpod の StateNotifier に一元化した。
//   メリット：
//     ・mounted チェックが不要（StateNotifier は Widget に依存しない）
//     ・GeminiService / BusinessCardService を直接 new せず
//       Provider 経由で取得するため依存関係が明確
//
// 【画面遷移】
//   完了後：popUntil で CardsPage（最初の画面）まで一気に戻る
//   処理中：戻るボタン無効（誤タップ防止）
//
// 【裏面対応】
//   CardImagePair で表面＋裏面をセットで Gemini に送る。
//   裏面がない場合（backImagePath == null）は表面だけで解析。
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/card_providers.dart';
import 'scan_step.dart';

class BatchAnalyzePage extends ConsumerStatefulWidget {
  final List<CardScanResult> scanResults;
  const BatchAnalyzePage({super.key, required this.scanResults});

  @override
  ConsumerState<BatchAnalyzePage> createState() => _BatchAnalyzePageState();
}

class _BatchAnalyzePageState extends ConsumerState<BatchAnalyzePage> {
  @override
  void initState() {
    super.initState();
    // 画面が表示されたらすぐ解析開始
    // addPostFrameCallback = 最初のフレームが描画された後に実行する
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // analyzeProvider の AnalyzeNotifier を取得して解析開始
      ref.read(analyzeProvider.notifier).startAnalysis(widget.scanResults);
    });
  }

  @override
  Widget build(BuildContext context) {
    // analyzeProvider を watch することで、
    // StateNotifier の state が変わるたびに自動で再描画される
    final state = ref.watch(analyzeProvider);

    return PopScope(
      // 処理中は誤って戻るボタンを押してもキャンセルできないようにする
      canPop: !state.isProcessing,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('名刺を読み取り中'),
          automaticallyImplyLeading: !state.isProcessing,
        ),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ステータスアイコン
              _buildStatusIcon(state),
              const SizedBox(height: 32),

              // ステータステキスト
              Text(
                state.statusText,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // プログレスバー（処理中のみ表示）
              if (state.isProcessing) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    // totalSteps が 0 のとき null → 不確定アニメ
                    value: state.totalSteps > 0
                        ? state.currentStep / state.totalSteps
                        : null,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${state.currentStep} / ${state.totalSteps} 枚',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],

              // エラー表示
              if (state.errorText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    state.errorText,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    // 再試行：状態をリセットしてから再実行
                    ref.read(analyzeProvider.notifier).reset();
                    ref.read(analyzeProvider.notifier)
                        .startAnalysis(widget.scanResults);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
              ],

              // 完了時のボタン
              if (state.isDone) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    // popUntil で最初の画面（CardsPage）まで一気に戻る
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('一覧に戻る'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ステータスに応じたアイコンを返す
  Widget _buildStatusIcon(AnalyzeState state) {
    if (state.errorText.isNotEmpty) {
      return const Icon(Icons.error_outline, size: 80, color: Colors.red);
    }
    if (state.isDone) {
      return const Icon(Icons.check_circle_outline,
          size: 80, color: Colors.green);
    }
    return SizedBox(
      width: 80,
      height: 80,
      child: CircularProgressIndicator(
        strokeWidth: 6,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
