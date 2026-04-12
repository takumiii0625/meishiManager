// ============================================================
// mail_app_service.dart
// メールアプリの選択・保存・起動を管理するサービス
//
// 【対応メールアプリ】
//   Gmail / Outlook / Spark / Airmail /
//   Yahoo Mail / Fastmail / Proton Mail / デフォルト（Apple Mail）
//
// 【URLスキームの仕組み】
//   各メールアプリは独自のURLスキームを持っている
//   例: googlegmail://co?to=xxx → Gmailで新規メール作成
//   canLaunchUrl() で端末にインストールされているか確認できる
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// SharedPreferences のキー
const _kMailAppKey = 'selected_mail_app';

// ── メールアプリの定義 ────────────────────────────────────
class MailApp {
  const MailApp({
    required this.id,      // 内部ID（SharedPreferencesに保存）
    required this.name,    // 表示名
    required this.scheme,  // URLスキーム（canLaunchUrl の確認用）
  });

  final String id;
  final String name;
  final String scheme;

  /// メール作成URLを生成する
  /// Web版はブラウザURL、モバイルはURLスキームを使う
  Uri composeUri(String to) {
    if (kIsWeb) {
      // Web版：ブラウザで開けるURLを使う
      switch (id) {
        case 'gmail':
          // GmailのWeb作成画面
          return Uri.parse(
              'https://mail.google.com/mail/?view=cm&to=${Uri.encodeComponent(to)}');
        case 'outlook':
          // OutlookのWeb作成画面
          return Uri.parse(
              'https://outlook.live.com/mail/0/deeplink/compose?to=${Uri.encodeComponent(to)}');
        case 'yahoo':
          // Yahoo Mail Web
          return Uri.parse(
              'https://compose.mail.yahoo.com/?to=${Uri.encodeComponent(to)}');
        case 'protonmail':
          // Proton Mail Web
          return Uri.parse(
              'https://mail.proton.me/u/0/inbox#compose?to=${Uri.encodeComponent(to)}');
        default:
          // それ以外はmailto:（ブラウザのデフォルトメールが開く）
          return Uri(scheme: 'mailto', path: to);
      }
    } else {
      // モバイル版：URLスキームを使う
      switch (id) {
        case 'gmail':
          return Uri.parse('googlegmail://co?to=$to');
        case 'outlook':
          return Uri.parse('ms-outlook://compose?to=$to');
        case 'spark':
          return Uri.parse('readdle-spark://compose?recipient=$to');
        case 'airmail':
          return Uri.parse('airmail://compose?to=$to');
        case 'ymail':
          return Uri.parse('ymail://mail/compose?to=$to');
        case 'fastmail':
          return Uri.parse('fastmail://mail/compose?to=$to');
        case 'protonmail':
          return Uri.parse('protonmail://compose?to=$to');
        default:
          return Uri(scheme: 'mailto', path: to);
      }
    }
  }
}

// 対応しているメールアプリ一覧
const List<MailApp> kMailApps = [
  MailApp(id: 'default',    name: 'デフォルト（Apple Mail）', scheme: 'mailto'),
  MailApp(id: 'gmail',      name: 'Gmail',       scheme: 'googlegmail'),
  MailApp(id: 'outlook',    name: 'Outlook',     scheme: 'ms-outlook'),
  MailApp(id: 'spark',      name: 'Spark',       scheme: 'readdle-spark'),
  MailApp(id: 'airmail',    name: 'Airmail',     scheme: 'airmail'),
  MailApp(id: 'ymail',      name: 'Yahoo Mail',  scheme: 'ymail'),
  MailApp(id: 'fastmail',   name: 'Fastmail',    scheme: 'fastmail'),
  MailApp(id: 'protonmail', name: 'Proton Mail', scheme: 'protonmail'),
];

// Web版専用のメールアプリ一覧（ブラウザURL対応のもののみ）
const List<MailApp> kWebMailApps = [
  MailApp(id: 'default',    name: 'デフォルト（OS設定）', scheme: 'mailto'),
  MailApp(id: 'gmail',      name: 'Gmail',       scheme: 'https'),
  MailApp(id: 'outlook',    name: 'Outlook',     scheme: 'https'),
  MailApp(id: 'yahoo',      name: 'Yahoo Mail',  scheme: 'https'),
  MailApp(id: 'protonmail', name: 'Proton Mail', scheme: 'https'),
];

// ── SharedPreferences から選択済みアプリを読み込む ─────────
final selectedMailAppProvider =
    AsyncNotifierProvider<SelectedMailAppNotifier, MailApp>(
  SelectedMailAppNotifier.new,
);

class SelectedMailAppNotifier extends AsyncNotifier<MailApp> {
  @override
  Future<MailApp> build() async {
    final prefs = await SharedPreferences.getInstance();
    final id    = prefs.getString(_kMailAppKey) ?? 'default';
    return kMailApps.firstWhere(
      (a) => a.id == id,
      orElse: () => kMailApps.first, // 見つからなければデフォルト
    );
  }

  /// メールアプリを選択して保存する
  Future<void> select(MailApp app) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMailAppKey, app.id);
    state = AsyncValue.data(app);
  }
}

// ── 端末にインストール済みのアプリだけ取得する ───────────────
final installedMailAppsProvider = FutureProvider<List<MailApp>>((ref) async {
  final result = <MailApp>[];
  for (final app in kMailApps) {
    // デフォルトは常に追加
    if (app.id == 'default') {
      result.add(app);
      continue;
    }
    // URLスキームで起動可能かチェック
    final uri = Uri.parse('${app.scheme}://');
    if (await canLaunchUrl(uri)) {
      result.add(app);
    }
  }
  return result;
});

// ── メール送信の共通処理 ─────────────────────────────────
Future<void> launchMailApp(MailApp app, String to) async {
  final uri = app.composeUri(to);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    // フォールバック：mailto:
    final fallback = Uri(scheme: 'mailto', path: to);
    if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback);
    }
  }
}
