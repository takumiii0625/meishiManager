import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Web/モバイルでファイル選択を切り替えるconditional import
import 'image_picker_web_helper_stub.dart'
    if (dart.library.html) 'image_picker_web_helper.dart';

import '../../../providers/auth_providers.dart';
import '../../../providers/card_providers.dart';
import 'cards_theme.dart';

class AddCardDialog extends ConsumerStatefulWidget {
  const AddCardDialog({super.key});

  @override
  ConsumerState<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends ConsumerState<AddCardDialog> {
  final _nameCtrl       = TextEditingController();
  final _companyCtrl    = TextEditingController();
  final _industryCtrl   = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _jobLevelCtrl   = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _prefectureCtrl = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _notesCtrl      = TextEditingController();

  bool _isLoading   = false;
  String? _errorMsg;

  // 画像関連（表面・裏面）
  Uint8List? _frontImageBytes;
  String?    _frontImageFileName;
  Uint8List? _backImageBytes;
  String?    _backImageFileName;
  bool       _isUploadingImage = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _industryCtrl.dispose();
    _departmentCtrl.dispose();
    _jobLevelCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _prefectureCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── 画像を選択する（isSide: 'front' or 'back'）──
  Future<void> _pickImage(String isSide) async {
    if (kIsWeb) {
      await _pickImageWeb(isSide);
    } else {
      await _pickImageMobile(isSide);
    }
  }

  Future<void> _pickImageWeb(String isSide) async {
    final result = await pickImageFromWeb();
    if (result == null) return;
    setState(() {
      if (isSide == 'front') {
        _frontImageBytes    = result.bytes;
        _frontImageFileName = result.name;
      } else {
        _backImageBytes    = result.bytes;
        _backImageFileName = result.name;
      }
    });
  }

  Future<void> _pickImageMobile(String isSide) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      if (isSide == 'front') {
        _frontImageBytes    = bytes;
        _frontImageFileName = picked.name;
      } else {
        _backImageBytes    = bytes;
        _backImageFileName = picked.name;
      }
    });
  }

  // ── Storageに画像をアップロードしてURLを返す ──
  Future<String?> _uploadImage(
      String uid, Uint8List bytes, String prefix) async {
    setState(() => _isUploadingImage = true);
    try {
      final fileName =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('cards')
          .child(fileName);
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await storageRef.getDownloadURL();
    } catch (e) {
      setState(() => _errorMsg = '画像のアップロードに失敗しました: $e');
      return null;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = '氏名を入力してください');
      return;
    }
    if (_companyCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = '会社名を入力してください');
      return;
    }

    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    if (uid.isEmpty) {
      setState(() => _errorMsg = 'ログインが確認できません。再ログインしてください');
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      // 画像があればアップロード
      final frontImageUrl = _frontImageBytes != null
          ? await _uploadImage(uid, _frontImageBytes!, 'front')
          : null;
      final backImageUrl = _backImageBytes != null
          ? await _uploadImage(uid, _backImageBytes!, 'back')
          : null;

      await ref.read(cardRepositoryProvider).addCard(
        uid,
        name:          _nameCtrl.text.trim(),
        company:       _companyCtrl.text.trim(),
        industry:      _industryCtrl.text.trim(),
        department:    _departmentCtrl.text.trim(),
        jobLevel:      _jobLevelCtrl.text.trim(),
        phone:         _phoneCtrl.text.trim(),
        email:         _emailCtrl.text.trim(),
        prefecture:    _prefectureCtrl.text.trim(),
        address:       _addressCtrl.text.trim(),
        notes:         _notesCtrl.text.trim(),
        frontImageUrl: frontImageUrl ?? '',
        backImageUrl:  backImageUrl ?? '',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_nameCtrl.text.trim()} の名刺を追加しました'),
          backgroundColor: CardsColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() => _errorMsg = 'エラーが発生しました: \$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ヘッダー ──
              Row(
                children: [
                  const Expanded(
                    child: Text('名刺を追加',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: CardsColors.textMain)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: CardsColors.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── エラー ──
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: CardsColors.redBg,
                    border: Border.all(
                        color: CardsColors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: CardsColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                fontSize: 12, color: CardsColors.red))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // ── 画像アップロード ──
              const Text('名刺画像（任意）',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CardsColors.textMid)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _imageArea('表面', 'front',
                      _frontImageBytes,
                      () => setState(() {
                        _frontImageBytes    = null;
                        _frontImageFileName = null;
                      }))),
                  const SizedBox(width: 12),
                  Expanded(child: _imageArea('裏面', 'back',
                      _backImageBytes,
                      () => setState(() {
                        _backImageBytes    = null;
                        _backImageFileName = null;
                      }))),
                ],
              ),
              const SizedBox(height: 16),

              // ── 基本情報 ──
              _sectionLabel('基本情報'),
              _field('氏名（必須）', _nameCtrl,
                  hint: '例: 山田 太郎'),
              _field('会社名（必須）', _companyCtrl,
                  hint: '例: 株式会社〇〇'),
              _field('業種', _industryCtrl,
                  hint: '例: IT・ソフトウェア、製造業'),

              // ── 所属情報 ──
              _sectionLabel('所属情報'),
              _field('部署', _departmentCtrl,
                  hint: '例: 営業部・技術開発部・経営企画室'),
              _field('役職', _jobLevelCtrl,
                  hint: '例: 部長・代表取締役・営業担当'),

              // ── 連絡先 ──
              _sectionLabel('連絡先'),
              _field('電話番号', _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  hint: '例: 090-0000-0000'),
              _field('メール', _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  hint: '例: yamada@example.com'),

              // ── 住所 ──
              _sectionLabel('住所'),
              _field('都道府県', _prefectureCtrl,
                  hint: '例: 東京都・大阪府・愛知県'),
              _field('住所（詳細）', _addressCtrl,
                  hint: '例: 渋谷区渋谷1-2-3'),

              // ── メモ ──
              _sectionLabel('メモ'),
              _field('メモ', _notesCtrl,
                  maxLines: 3,
                  hint: '自由入力'),
              const SizedBox(height: 24),

              // ── フッター ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CardsColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('キャンセル',
                        style: TextStyle(color: CardsColors.textSub)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CardsColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('追加する',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── セクションラベル ──
  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CardsColors.textSub,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            const Divider(height: 1, color: CardsColors.border),
          ],
        ),
      );

  // ── 画像エリアウィジェット ──
  Widget _imageArea(
    String label,
    String isSide,
    Uint8List? imageBytes,
    VoidCallback onRemove,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CardsColors.textMid)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _isLoading ? null : () => _pickImage(isSide),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: CardsColors.bg,
                border: Border.all(
                  color: imageBytes != null
                      ? CardsColors.primary
                      : CardsColors.border,
                  width: imageBytes != null ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(imageBytes, fit: BoxFit.cover),
                          Positioned(
                            top: 6, right: 6,
                            child: GestureDetector(
                              onTap: onRemove,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 24, color: CardsColors.textSub),
                        const SizedBox(height: 4),
                        const Text('クリックして選択',
                            style: TextStyle(
                                fontSize: 11, color: CardsColors.textSub)),
                        const SizedBox(height: 2),
                        const Text('JPG / PNG',
                            style: TextStyle(
                                fontSize: 10, color: CardsColors.textSub)),
                      ],
                    ),
            ),
          ),
        ],
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: CardsColors.textMain),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 13, color: CardsColors.textSub),
            labelStyle: const TextStyle(
                fontSize: 14, color: CardsColors.textMid),
            floatingLabelStyle: const TextStyle(
                fontSize: 12, color: CardsColors.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CardsColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CardsColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CardsColors.primary)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
}
