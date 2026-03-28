// ============================================================
// multi_scan_page.dart
// 連続撮影画面
//
// 【流れ】
//   ① 表面を撮影
//   ② 「裏面も撮る？」確認 → Yes or スキップ
//   ③ ①②を繰り返す（最大5枚）
//   ④ 「解析する」ボタン → BatchAnalyzePage へ直接push
//
// 【変更点（案A対応）】
//   以前は Navigator.pop でバッチを返して
//   BatchRegisterPage → BatchAnalyzePage という流れだったが、
//   BatchRegisterPage を廃止したため、
//   _goToAnalyze で直接 BatchAnalyzePage へ push する方式に変更。
//   BatchAnalyzePage 完了後は popUntil で CardsPage まで一気に戻る。

//   縦名刺対応：撮影後に回転確認ダイアログを表示
//      - 表面撮影後に「この向きで合ってますか？」を確認
//      - 「90°回転」ボタンで画像を回転できる
//      - 向きが確定したら裏面確認へ進む
// ============================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'scan_step.dart';
import 'batch_analyze_page.dart';

class MultiScanPage extends StatefulWidget {
  final int maxBatchSize;
  const MultiScanPage({super.key, this.maxBatchSize = 5});

  @override
  State<MultiScanPage> createState() => _MultiScanPageState();
}

class _MultiScanPageState extends State<MultiScanPage> {
  // 撮影済みカードのリスト（表面+裏面のペア）
  final List<CardScanResult> _batch = [];
  // 現在撮影した表面のパス（裏面確認待ち状態）
  String? _currentFrontPath;
  bool _scanning = false;

  // ── スキャナーを起動して画像パスを返す ──────────────────
  Future<String?> _launchScanner() async {
    final pictures = await CunningDocumentScanner.getPictures(
      isGalleryImportAllowed: false,
      iosScannerOptions: const IosScannerOptions(
        imageFormat: IosImageFormat.jpg,
        jpgCompressionQuality: 0.82,
      ),
    );
    if (pictures == null || pictures.isEmpty) return null;
    return pictures.first;
  }

  // ── 表面を撮影 → 回転確認ダイアログへ ────────────────────
  Future<void> _scanFront() async {
    if (_scanning) return;
    setState(() => _scanning = true);

    try {
      final path = await _launchScanner();
      if (!mounted) return;
      if (path == null) {
        // キャンセルされた場合
        setState(() => _scanning = false);
        return;
      }

      // ★ 撮影後に回転確認ダイアログを表示
      //   縦名刺が横向きになっていた場合などに回転できる
      final confirmedPath = await _showRotateDialog(path);
      if (!mounted) return;

      if (confirmedPath == null) {
        // ダイアログをキャンセルした場合は表面撮影に戻る
        setState(() => _scanning = false);
        return;
      }

      setState(() {
        _currentFrontPath = confirmedPath;
        _scanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('スキャン失敗: $e')));
    }
  }

  // ── 裏面を撮影 → 回転確認ダイアログへ ────────────────────
  Future<void> _scanBack() async {
    if (_scanning) return;
    setState(() => _scanning = true);

    try {
      final path = await _launchScanner();
      if (!mounted) return;
      if (path == null) {
        setState(() => _scanning = false);
        return;
      }

      // 裏面も同様に回転確認
      final confirmedPath = await _showRotateDialog(path);
      if (!mounted) return;

      _commitCard(backPath: confirmedPath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
    }
  }

  // ── 回転確認ダイアログ ─────────────────────────────────
  // 撮影直後に向きを確認して回転できる
  //
  // 戻り値:
  //   String? = 確定した画像パス（null = キャンセル）
  Future<String?> _showRotateDialog(String imagePath) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RotateConfirmSheet(imagePath: imagePath),
    );
  }

  void _skipBack() => _commitCard(backPath: null);

  // ── 1枚のカードをバッチに追加して確定 ──────────────────
  void _commitCard({required String? backPath}) {
    if (_currentFrontPath == null) return;

    _batch.add(CardScanResult(
      frontImagePath: _currentFrontPath!,
      backImagePath: backPath,
    ));

    // 表面パスをクリア → 表面撮影待機画面に戻る
    setState(() {
      _currentFrontPath = null;
      _scanning = false;
    });

    // 上限枚数に達したら自動で解析画面へ
    if (_batch.length >= widget.maxBatchSize) _goToAnalyze();
  }

  // ── 解析画面へ遷移する ─────────────────────────────────
  // ★ 変更点：以前は pop でバッチを返していたが、
  //   直接 BatchAnalyzePage へ push する方式に変更した。
  //   BatchRegisterPage が不要になったため。
  void _goToAnalyze() {
    if (!mounted || _batch.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BatchAnalyzePage(
          scanResults: List<CardScanResult>.from(_batch),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 裏面確認中かどうかで表示を切り替える
    if (_currentFrontPath != null) return _buildAskBackScreen();
    return _buildFrontScreen();
  }

  // ── 表面撮影待機画面 ────────────────────────────────────
  Widget _buildFrontScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('名刺スキャン（${_batch.length}/${widget.maxBatchSize}枚）'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 撮影済みサムネイル一覧
            if (_batch.isNotEmpty) ...[
              _buildBatchPreview(),
              const SizedBox(height: 8),
              Text('${_batch.length}枚撮影済み',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
            ],

            const Icon(Icons.document_scanner, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _batch.isEmpty ? '名刺を撮影してください' : '次の名刺を撮影します',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),

            // 表面撮影ボタン
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _scanning ? null : _scanFront,
                icon: _scanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_scanning ? '読み取り中...' : '表面を撮影'),
              ),
            ),
            const SizedBox(height: 12),

            // 案内テキスト①：スキャナーの操作方法
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text(
                  '名刺が自動認識されたら、右上の ✓ を押して確定してください',
                  style: TextStyle(fontSize: 13, color: Colors.blue),
                )),
              ]),
            ),
            const SizedBox(height: 8),
            // 案内テキスト②：縦名刺の回転について
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(children: [
                Icon(Icons.rotate_right, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text(
                  '縦名刺の場合は撮影後の確認画面で回転して調整できます',
                  style: TextStyle(fontSize: 13, color: Colors.orange),
                )),
              ]),
            ),
            const SizedBox(height: 16),

            // 解析ボタン（1枚以上溜まったら表示）
            if (_batch.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _goToAnalyze,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text('この${_batch.length}枚を読み取る'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 裏面確認画面 ────────────────────────────────────────
  Widget _buildAskBackScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('名刺スキャン（${_batch.length + 1}/${widget.maxBatchSize}枚）'),
        // 戻るボタンで表面撮影をキャンセル（この枚は破棄）
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _currentFrontPath = null;
            _scanning = false;
          }),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 表面のプレビュー画像
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_currentFrontPath!),
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text('表面を撮影しました',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('裏面も撮影しますか？'),
            const SizedBox(height: 12),

            // 裏面撮影時の案内
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text('裏面撮影後も向き確認画面が出ます',
                    style: TextStyle(fontSize: 13, color: Colors.blue))),
              ]),
            ),
            const SizedBox(height: 32),

            // スキップ / 裏面撮影
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanning ? null : _skipBack,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('スキップ'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _scanning ? null : _scanBack,
                    icon: const Icon(Icons.flip),
                    label: const Text('裏面を撮影'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 撮影済み枚数のサムネイルプレビュー
  Widget _buildBatchPreview() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: _batch.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(File(_batch[i].frontImagePath),
                width: 52, height: 64, fit: BoxFit.cover),
          ),
          if (_batch[i].backImagePath != null)
            Positioned(
              bottom: 2, right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.flip, size: 10, color: Colors.white),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── 回転確認ボトムシート ──────────────────────────────────
// 撮影後に向きを確認して必要なら90°回転できる
//
// 使い方:
//   「この向きで OK」→ 現在のパスを返す
//   「90°回転」→ 画像を回転して再表示
//   「キャンセル」→ null を返す（撮影し直し）
class _RotateConfirmSheet extends StatefulWidget {
  final String imagePath;
  const _RotateConfirmSheet({required this.imagePath});

  @override
  State<_RotateConfirmSheet> createState() => _RotateConfirmSheetState();
}

class _RotateConfirmSheetState extends State<_RotateConfirmSheet> {
  late String _currentPath;
  int _rotationDeg = 0; // 現在の回転角度（0 / 90 / 180 / 270）
  bool _rotating = false; // 回転処理中フラグ

  @override
  void initState() {
    super.initState();
    _currentPath = widget.imagePath;
  }

  // 画像を90°時計回りに回転する
  // flutter_image_compress の rotate オプションを使う
  Future<void> _rotate90() async {
    if (_rotating) return;
    setState(() => _rotating = true);

    try {
      _rotationDeg = (_rotationDeg + 90) % 360;

      // flutter_image_compress で回転した画像を一時ファイルとして保存
      final originalBytes = await File(_currentPath).readAsBytes();
      final rotated = await FlutterImageCompress.compressWithList(
        originalBytes,
        rotate: 90, // 90°時計回りに回転
        quality: 90,
        format: CompressFormat.jpeg,
      );

      // 一時ファイルに保存
      final dir = Directory(_currentPath).parent;
      final newPath = '${dir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(newPath).writeAsBytes(rotated);

      setState(() {
        _currentPath = newPath;
        _rotating = false;
      });
    } catch (e) {
      setState(() => _rotating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ハンドル
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),

            const Text('向きを確認してください',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('縦名刺の場合は「90°回転」で調整してください',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),

            // 画像プレビュー
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_currentPath),
                height: 200,
                fit: BoxFit.contain,
                key: ValueKey(_currentPath), // パスが変わったら再描画
              ),
            ),
            const SizedBox(height: 16),

            // 回転ボタン
            OutlinedButton.icon(
              onPressed: _rotating ? null : _rotate90,
              icon: _rotating
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.rotate_right),
              label: Text(_rotating ? '回転中...' : '90°回転'),
            ),
            const SizedBox(height: 12),

            // OK / キャンセル ボタン
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null), // キャンセル
                  child: const Text('撮り直す'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _currentPath), // 確定
                  child: const Text('この向きでOK'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
