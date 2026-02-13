import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_model.dart';
import '../repositories/card_repository.dart';
import 'auth_providers.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(firestoreProvider));
});

/// 名刺一覧（uid は auth_providers.dart の uidProvider を使う）
final cardsStreamProvider = StreamProvider<List<CardModel>>((ref) {
  final uid = ref.watch(uidProvider);

  // ★uidが空の間はFirestoreに行かない（起動直後の事故防止）
  if (uid.isEmpty) {
    return const Stream<List<CardModel>>.empty();
    // もしくは Stream.value(<CardModel>[])
  }

  return ref.watch(cardRepositoryProvider).watchCards(uid);
});

/// フォーム入力で追加するためのパラメータ
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

/// フォーム入力で追加
final addCardProvider =
    FutureProvider.autoDispose.family<void, AddCardParams>((ref, params) async {
  final uid = ref.read(uidProvider);
  await ref.watch(cardRepositoryProvider).addCard(
        uid,
        name: params.name,
        company: params.company,
        industry: params.industry,
        phone: params.phone,
        email: params.email,
        notes: params.notes,
      );
});

/// 1件の名刺を監視（詳細画面用）
final cardStreamProvider =
    StreamProvider.family<CardModel, String>((ref, cardId) {
  final uid = ref.watch(uidProvider);

  if (uid.isEmpty) {
    // ★uidが無い状態で詳細を開かない前提だけど、保険でエラーにせず待機
    return const Stream<CardModel>.empty();
  }

  final repo = ref.watch(cardRepositoryProvider);
  return repo.watchCard(uid, cardId);
});


/// 削除（長押し用）
final deleteCardProvider =
    FutureProvider.autoDispose.family<void, String>((ref, cardId) async {
  final uid = ref.read(uidProvider);
  await ref.watch(cardRepositoryProvider).deleteCard(uid, cardId);
});

/// 更新：フォーム入力で更新するためのパラメータ
class UpdateCardParams {
  UpdateCardParams({
    required this.cardId,
    required this.name,
    required this.company,
    this.industry = '',
    this.phone = '',
    this.email = '',
    this.notes = '',
    this.imageUrl = '',
    this.rawText = '',
  });

  final String cardId;
  final String name;
  final String company;
  final String industry;
  final String phone;
  final String email;
  final String notes;
  final String imageUrl;
  final String rawText;
}

/// 更新：フォーム入力で更新（uidはauthのuidProviderを使用）
final updateCardProvider =
    FutureProvider.autoDispose.family<void, UpdateCardParams>((ref, params) async {
  final uid = ref.read(uidProvider);
  final repo = ref.watch(cardRepositoryProvider);

  await repo.updateCard(
    uid,
    params.cardId,
    name: params.name,
    company: params.company,
    industry: params.industry,
    phone: params.phone,
    email: params.email,
    notes: params.notes,
    imageUrl: params.imageUrl,
    rawText: params.rawText,
  );
});
