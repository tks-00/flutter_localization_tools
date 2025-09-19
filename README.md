# Flutter Localization Tools

Flutter/Dart プロジェクトの多言語化対応を支援するツール集です。

## 概要

このリポジトリには、Flutter アプリの国際化（i18n）とローカライゼーション（l10n）を効率的に管理するための 2 つのツールが含まれています。日本語・英語の 2 言語対応を想定したシンプルな構成になっています。

## ツール

### 1. 日本語ハードコード文字列検出ツール (`find_japanese_hardcoded_strings.dart`)

Dart プロジェクト内の日本語でハードコードされた文字列を検出し、多言語化対応が必要な箇所を特定します。

#### 機能

- ひらがな、カタカナ、漢字を含む文字列リテラルを検出
- コメント内の日本語は除外（オプション）
- `debugPrint`、`Exception`、出力文内の日本語は除外
- 既存の ARB ファイルで管理されている文字列との重複をチェック
- ファイルパス、行番号、該当テキストを詳細表示

#### 使用方法

```bash
dart run tools/find_japanese_hardcoded_strings.dart
```

#### 実行例

```
🔍 日本語ハードコード文字列検出ツールを開始します...

🎯 対象ディレクトリ: lib

📚 既存のl10n文字列: 25件読み込み完了

📁 対象Dartファイル: 3件

🔍 検出結果: 15件の日本語文字列が見つかりました

📄 lib/samples/hardcoded_strings_sample.dart (12件)
────────────────────────────────────────────────────────────
🔴 行15: 'サンプルアプリ'
   title: const Text('サンプルアプリ'),

🔴 行20: "こんにちは、世界！"
   const Text("こんにちは、世界！"),
```

### 2. ARB ファイルキー比較ツール (`check_arb_keys.dart`)

複数の言語の ARB ファイル間でキーの整合性をチェックし、翻訳の漏れを検出します。

#### 機能

- 2 つの言語（英語、日本語）のキーを比較
- 各言語で不足しているキーを特定
- 一部の言語にのみ存在するキーを検出
- 言語固有のキー（他の言語に存在しないキー）を表示
- 統計情報の表示

#### 使用方法

```bash
dart run tools/check_arb_keys.dart
```

#### 実行例

```
EN: 12 keys
JA: 12 keys

============================================================
Total unique keys: 14

============================================================
Missing keys by language:
============================================================

EN missing 2 keys:
  - missingInEnglish
  - onlyJapanese

JA missing 2 keys:
  - missingInJapanese
  - onlyEnglish
```

## プロジェクト構成

```
lib/
├── l10n/                    # ARBファイル（多言語リソース）
│   ├── app_en.arb          # 英語
│   └── app_ja.arb          # 日本語
├── samples/                 # サンプルファイル
│   ├── hardcoded_strings_sample.dart  # 日本語ハードコード例
│   └── mixed_content_sample.dart      # 混在コンテンツ例
└── main.dart               # デモアプリのメイン
tools/
├── find_japanese_hardcoded_strings.dart  # 日本語検出ツール
└── check_arb_keys.dart                   # ARBキー比較ツール
```

## 設定

### 日本語検出ツールの設定

`find_japanese_hardcoded_strings.dart` 内の `defaultConfig` で設定を変更できます：

```dart
const defaultConfig = JapaneseDetectorConfig(
  targetDirectories: ['lib/views'],    // 検索対象ディレクトリ
  excludePatterns: ['.g.dart'],        // 除外ファイルパターン
  excludeFiles: ['lib/l10n/'],         // 除外ディレクトリ
  includeComments: false,              // コメント内も検索するか
  l10nDirectory: 'lib/l10n',           // ARBファイルのディレクトリ
);
```

### ARB キー比較ツールの設定

`check_arb_keys.dart` 内の `files` で対象言語を変更できます：

```dart
final files = {
  'en': '$basePath/app_en.arb',
  'ja': '$basePath/app_ja.arb',
};
```

## デモアプリの実行

サンプルファイルを含むデモアプリを実行できます：

```bash
flutter run
```

## 実際の使用例

### CI/CD パイプラインでの使用

```yaml
# GitHub Actions example
- name: Check Japanese hardcoded strings
  run: dart run tools/find_japanese_hardcoded_strings.dart

- name: Check ARB key consistency
  run: dart run tools/check_arb_keys.dart
```

### プレコミットフックでの使用

```bash
#!/bin/sh
# Pre-commit hook
dart run tools/find_japanese_hardcoded_strings.dart || exit 1
dart run tools/check_arb_keys.dart || exit 1
```

## 貢献

このプロジェクトへの貢献を歓迎します！以下の方法でご参加ください：

1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'feat: Add amazing feature'`)
4. ブランチをプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。

## 技術記事

このツールに関する詳細な技術記事は[こちら](リンクを挿入)をご覧ください。

---

**Flutter Localization Tools** - Flutter アプリの多言語化をより効率的に 🌍
