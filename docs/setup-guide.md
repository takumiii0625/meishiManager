# meishiManager プロジェクト構築手順

## 概要

- **アプリ名**: meishiManager
- **Bundle Identifier**: com.obfall.meishiManager
- **対応プラットフォーム**: iOS, Android, Web
- **Firebase機能**: Authentication, Cloud Firestore, Cloud Storage
- **リポジトリ**: git@github.com:takumiii0625/meishiManager.git

---

## Step 1: Flutter プロジェクト作成

```bash
flutter create --org com.obfall --project-name meishi_manager --platforms ios,android,web .
```

- `--org com.obfall` でパッケージ名の先頭部分を指定
- `--project-name meishi_manager` でプロジェクト名を指定（Flutter はスネークケース必須）
- `--platforms ios,android,web` で対応プラットフォームを指定

## Step 2: Firebase 依存パッケージ追加

```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
```

## Step 3: Firebase プロジェクト作成 & FlutterFire CLI 設定

### Firebase Console での作業

1. [Firebase Console](https://console.firebase.google.com/) でプロジェクトを作成
2. 以下のサービスを有効化:
   - **Authentication**: 構築 → Authentication → 始める → ログイン方法を有効化
   - **Cloud Firestore**: 構築 → Firestore Database → データベースを作成（ロケーション: `asia-northeast1`）
   - **Cloud Storage**: 構築 → Storage → 始める

### FlutterFire CLI でアプリ登録

```bash
# FlutterFire CLI インストール
dart pub global activate flutterfire_cli

# Firebase CLI ログイン
firebase login

# プロジェクト設定（iOS/Android/Web を自動登録、firebase_options.dart を自動生成）
flutterfire configure
```

## Step 4: main.dart に Firebase 初期化コードを追加

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

## Step 5: iOS 設定

### Podfile

`ios/Podfile` の最小デプロイターゲットを 16.0 に設定:

```ruby
platform :ios, '16.0'
```

Pod インストール:

```bash
cd ios && pod install && cd ..
```

### Xcode（ios/Runner.xcworkspace を開く）

1. **General** → **Minimum Deployments** を **16.0** に設定
2. **Signing & Capabilities** → **Team** に Apple Developer アカウントを選択
3. `GoogleService-Info.plist` がプロジェクトツリーにない場合は手動で追加

## Step 6: アプリ表示名を "meishiManager" に設定

| プラットフォーム | ファイル | 変更箇所 |
|---|---|---|
| Android | `android/app/src/main/AndroidManifest.xml` | `android:label="meishiManager"` |
| iOS | `ios/Runner/Info.plist` | `CFBundleDisplayName` → `meishiManager` |
| Web | `web/index.html` | `<title>meishiManager</title>` |

## Step 7: Git リポジトリ接続 & 初回プッシュ

```bash
git init
git remote add origin git@github.com:takumiii0625/meishiManager.git
git add .
git commit -m "Initial commit: Flutter project with Firebase setup"
git push -u origin main
```

---

## トラブルシューティング

### `Module 'cloud_firestore' not found`（Xcode）

Pod が未インストールの場合に発生:

```bash
cd ios && pod install && cd ..
```

解決しない場合はキャッシュクリア:

```bash
cd ios && pod deintegrate && pod cache clean --all && pod install && cd ..
```

### `CocoaPods could not find compatible versions`

`ios/Podfile` の最小デプロイターゲットが低い場合に発生。`16.0` 以上に設定して `pod install` を再実行。
