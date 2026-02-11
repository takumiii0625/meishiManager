import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_model.dart';
import '../repositories/card_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(firestoreProvider));
});

// まずはuid固定（Auth入れたら差し替え）
const _dummyUid = 'dummy_uid';
final uidProvider = Provider<String>((ref) => _dummyUid);

final cardsStreamProvider = StreamProvider<List<CardModel>>((ref) {
  return ref.watch(cardRepositoryProvider).watchCards(_dummyUid);
});

/// 既存：動作確認用（ダミー追加）
final addDummyCardProvider = FutureProvider.autoDispose<void>((ref) async {
  await ref.watch(cardRepositoryProvider).addDummy(_dummyUid);
});

/// 追加：フォーム入力で追加するためのパラメータ
class AddCardParams {
  AddCardParams({
    required this.name,
    required this.company,
    this.industry = '',
    this.phone = '',
    this.email = '',
    this.notes = '',
  });

  final String name;
  final String company;
  final String industry;
  final String phone;
  final String email;
  final String notes;
}

/// 追加：フォーム入力で追加（uidはdummyを使用）
final addCardProvider = FutureProvider.autoDispose.family<void, AddCardParams>((
  ref,
  params,
) async {
  await ref
      .watch(cardRepositoryProvider)
      .addCard(
        _dummyUid,
        name: params.name,
        company: params.company,
        industry: params.industry,
        phone: params.phone,
        email: params.email,
        notes: params.notes,
      );
});

final cardStreamProvider = StreamProvider.family<CardModel, String>((
  ref,
  cardId,
) {
  final uid = ref.watch(uidProvider);
  final repo = ref.watch(cardRepositoryProvider);
  return repo.watchCard(uid, cardId);
});
