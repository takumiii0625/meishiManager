// ============================================================
// card_add_page.dart
// 手動登録画面
//
// 【概要】
//   フォームに入力して名刺を手動で登録する画面。
//   OCRが使えない場合や、名刺がない場合に使う。
//
// 【フィールド構成】
//   画像：表面（必須ではない）・裏面（任意）
//   基本情報：氏名・会社名・業種
//   所属情報：部署（優先度高）・役職（優先度低）
//   連絡先：電話・メール
//   住所：都道府県・住所詳細
//   メモ
//
// 【画像の登録方法】
//   cunning_document_scanner でスキャン or フォトライブラリから選択
//   → BusinessCardService.uploadImage() で Firebase Storage にアップロード
//   → Firestore の frontImageUrl / backImageUrl に保存
// ============================================================

import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/card_providers.dart';
import '../../services/business_card_service.dart';

class CardAddPage extends ConsumerStatefulWidget {
  const CardAddPage({super.key});

  @override
  ConsumerState<CardAddPage> createState() => _CardAddPageState();
}

class _CardAddPageState extends ConsumerState<CardAddPage> {
  final _formKey = GlobalKey<FormState>();

  // 各フィールドのコントローラー
  final _name       = TextEditingController();
  final _company    = TextEditingController();
  final _industry   = TextEditingController();
  final _department = TextEditingController(); // 部署（優先度高）
  final _jobLevel   = TextEditingController(); // 役職（優先度低）
  final _phone      = TextEditingController();
  final _email      = TextEditingController();
  final _address    = TextEditingController();
  final _prefecture = TextEditingController();
  final _notes      = TextEditingController();

  // 選択した画像のローカルパス（null = まだ選んでいない）
  String? _frontImagePath; // 表面
  String? _backImagePath;  // 裏面

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name, _company, _industry, _department, _jobLevel,
      _phone, _email, _address, _prefecture, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── バリデーター（入力チェック）────────────────────────
  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label は必須です';
    return null;
  }

  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
        ? null
        : 'メール形式が正しくありません';
  }

  String? _phoneValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return RegExp(r'^[0-9\-\s\(\)]+$').hasMatch(s)
        ? null
        : '電話番号は数字と記号（- 等）で入力してください';
  }

  // ── スキャナーを起動して画像パスを取得 ────────────────
  // cunning_document_scanner を使ってカメラでスキャンする。
  // 戻り値: 撮影した画像のローカルパス（キャンセルした場合は null）
  Future<String?> _launchScanner() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        isGalleryImportAllowed: false,
        iosScannerOptions: const IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.82,
        ),
      );
      if (pictures == null || pictures.isEmpty) return null;
      return pictures.first;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('スキャン失敗: $e')));
      }
      return null;
    }
  }

  // ── フォトライブラリから画像を選択 ───────────────────
  // image_picker を使って写真アプリから選ぶ。
  // 戻り値: 選んだ画像のローカルパス（キャンセルした場合は null）
  Future<String?> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // ある程度圧縮してから返す
      );
      return picked?.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('画像の選択に失敗: $e')));
      }
      return null;
    }
  }

  // ── 画像取得方法を選ぶボトムシートを表示 ────────────────
  // 「スキャン」か「フォトライブラリ」かを選ばせる。
  // isSide: 'front'（表面）か 'back'（裏面）かを指定する。
  Future<void> _pickImage(String isSide) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ハンドル
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              isSide == 'front' ? '表面の画像を選択' : '裏面の画像を選択',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.document_scanner,
                  color: Color(0xFF1E40AF)),
              title: const Text('スキャンして追加'),
              subtitle: const Text('カメラで名刺を撮影します'),
              onTap: () => Navigator.pop(ctx, 'scan'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF475569)),
              title: const Text('フォトライブラリから選択'),
              subtitle: const Text('写真アプリから画像を選びます'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            // 画像がすでにある場合だけ「削除」を表示
            if ((isSide == 'front' && _frontImagePath != null) ||
                (isSide == 'back'  && _backImagePath  != null))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('画像を削除', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    String? path;
    if (result == 'scan') {
      path = await _launchScanner();
    } else if (result == 'gallery') {
      path = await _pickFromGallery();
    } else if (result == 'delete') {
      // 削除：対象のパスを null に戻す
      setState(() {
        if (isSide == 'front') _frontImagePath = null;
        if (isSide == 'back')  _backImagePath  = null;
      });
      return;
    }

    if (path == null) return;

    setState(() {
      if (isSide == 'front') _frontImagePath = path;
      if (isSide == 'back')  _backImagePath  = path;
    });
  }

  // ── 保存処理 ─────────────────────────────────────────
  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      // 画像をアップロードして URL を取得する
      // uploadImage は BusinessCardService のメソッド
      // prefix='front' でファイル名を区別する
      final cardService = BusinessCardService();
      final frontImageUrl = (_frontImagePath != null && _frontImagePath!.isNotEmpty)
          ? await cardService.uploadImage(_frontImagePath!, prefix: 'front') ?? ''
          : '';
      final backImageUrl = (_backImagePath != null && _backImagePath!.isNotEmpty)
          ? await cardService.uploadImage(_backImagePath!, prefix: 'back') ?? ''
          : '';

      final params = AddCardParams(
        name:          _name.text.trim(),
        company:       _company.text.trim(),
        industry:      _industry.text.trim(),
        department:    _department.text.trim(),
        jobLevel:      _jobLevel.text.trim(),
        phone:         _phone.text.trim(),
        email:         _email.text.trim(),
        address:       _address.text.trim(),
        prefecture:    _prefecture.text.trim(),
        notes:         _notes.text.trim(),
        frontImageUrl: frontImageUrl, // ← アップロード済みのURL
        backImageUrl:  backImageUrl,  // ← 裏面がなければ空文字
      );

      await ref.read(addCardProvider(params).future);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名刺を登録しました')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存に失敗: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手動で登録'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? '保存中...' : '保存',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 名刺画像（表面・裏面）────────────────────────
              _SectionLabel('名刺画像（任意）'),
              Row(
                children: [
                  // 表面
                  Expanded(
                    child: _ImagePicker(
                      label: '表面',
                      imagePath: _frontImagePath,
                      onTap: () => _pickImage('front'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 裏面
                  Expanded(
                    child: _ImagePicker(
                      label: '裏面（任意）',
                      imagePath: _backImagePath,
                      onTap: () => _pickImage('back'),
                    ),
                  ),
                ],
              ),
              // 案内テキスト
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    'スキャンまたはライブラリから追加できます',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ]),
              ),

              // ── 基本情報 ──────────────────────────────────
              _SectionLabel('基本情報'),
              _Field(
                ctrl: _name,
                label: '氏名',
                required: true,
                validator: (v) => _required(v, '氏名'),
                action: TextInputAction.next,
              ),
              _Field(
                ctrl: _company,
                label: '会社名',
                required: true,
                validator: (v) => _required(v, '会社名'),
                action: TextInputAction.next,
              ),
              _Field(
                ctrl: _industry,
                label: '業種',
                hint: '例: IT・ソフトウェア、製造業',
                action: TextInputAction.next,
              ),

              // ── 所属情報（部署＞役職の優先度）──────────────
              const SizedBox(height: 16),
              _SectionLabel('所属情報'),
              _Field(
                ctrl: _department,
                label: '部署',
                hint: '例: 営業部・技術開発部・経営企画室',
                action: TextInputAction.next,
              ),
              _Field(
                ctrl: _jobLevel,
                label: '役職',
                hint: '例: 部長・代表取締役・営業担当',
                action: TextInputAction.next,
              ),

              // ── 連絡先 ──────────────────────────────────
              const SizedBox(height: 16),
              _SectionLabel('連絡先'),
              _Field(
                ctrl: _phone,
                label: '電話番号',
                keyboard: TextInputType.phone,
                validator: _phoneValidator,
                action: TextInputAction.next,
              ),
              _Field(
                ctrl: _email,
                label: 'メール',
                keyboard: TextInputType.emailAddress,
                validator: _emailValidator,
                action: TextInputAction.next,
              ),

              // ── 住所 ─────────────────────────────────────
              const SizedBox(height: 16),
              _SectionLabel('住所'),
              _Field(
                ctrl: _prefecture,
                label: '都道府県',
                hint: '例: 東京都・大阪府・愛知県',
                action: TextInputAction.next,
              ),
              _Field(
                ctrl: _address,
                label: '住所（詳細）',
                hint: '例: 渋谷区渋谷1-2-3',
                maxLines: 2,
              ),

              // ── メモ ─────────────────────────────────────
              const SizedBox(height: 16),
              _SectionLabel('メモ'),
              _Field(
                ctrl: _notes,
                label: 'メモ',
                hint: '自由入力',
                maxLines: 4,
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? '保存中...' : '登録する'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 画像選択ウィジェット ─────────────────────────────────
// 画像がある場合はプレビューを表示し、
// タップするとスキャン/ライブラリ選択のボトムシートを開く。
class _ImagePicker extends StatelessWidget {
  final String label;
  final String? imagePath; // null = 未選択
  final VoidCallback onTap;

  const _ImagePicker({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(
            // 画像あり: 青いボーダー / なし: グレーのボーダー
            color: imagePath != null
                ? const Color(0xFF1E40AF)
                : const Color(0xFFCBD5E1),
            width: imagePath != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: imagePath != null
            // 画像あり: プレビュー表示
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(
                      File(imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 右上に「変更」バッジを表示
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('変更',
                          style: TextStyle(
                              fontSize: 10, color: Colors.white)),
                    ),
                  ),
                  // 下部にラベル
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(9)),
                      ),
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white)),
                    ),
                  ),
                ],
              )
            // 画像なし: プレースホルダー
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: imagePath != null
                          ? const Color(0xFF1E40AF)
                          : const Color(0xFFCBD5E1)),
                  const SizedBox(height: 6),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('タップして追加',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFFCBD5E1))),
                ],
              ),
      ),
    );
  }
}

// ── セクションラベル ──────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── テキストフィールド ────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final bool required;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputAction? action;

  const _Field({
    required this.ctrl,
    required this.label,
    this.hint,
    this.required = false,
    this.keyboard,
    this.validator,
    this.maxLines = 1,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: required ? '$label（必須）' : label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        textInputAction: action,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
