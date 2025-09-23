# Flutter Localization Tools

Flutter/Dart プロジェクトの多言語化対応を支援するツール集です。

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
fvm dart run tools/find_japanese_hardcoded_strings.dart
```

#### 実行例

```
日本語ハードコード文字列検出スクリプトを開始します...

対象ディレクトリ: lib/views
既存のl10n文字列: 2件読み込み完了
対象Dartファイル: 1件

検出結果: 8件の日本語文字列が見つかりました

lib/views/samples/sample_screen.dart (8件)
────────────────────────────────────────────────────────────
行19: 'ローカライゼーション ツール デモ'
   title: const Text('ローカライゼーション ツール デモ'),

行27: 'フルーツリスト'
   'フルーツリスト',
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
fvm dart run tools/check_arb_keys.dart
```

#### 実行例

```
EN: 2個のキー
JA: 2個のキー

============================================================
合計キー数: 3

============================================================
言語別の不足キー:
============================================================

EN に不足している1個のキー:
  - banana

JA に不足している1個のキー:
  - grape

============================================================
一部の言語にのみ存在するキー:
============================================================

'banana':
  存在する言語: JA
  不足している言語: EN

'grape':
  存在する言語: EN
  不足している言語: JA

============================================================
詳細統計:
============================================================

EN 固有キー (1個):
  - grape

JA 固有キー (1個):
  - banana
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

`find_japanese_hardcoded_strings.dart` 内の `defaultConfig` で設定を変更できます。

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

`check_arb_keys.dart` 内の `files` で対象言語を変更できます。

```dart
final files = {
  'en': '$basePath/app_en.arb',
  'ja': '$basePath/app_ja.arb',
};
```

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/[your-username]/flutter_localization_tools.git
cd flutter_localization_tools
```

### 2. FVM のセットアップ

このプロジェクトでは FVM を使用して Flutter バージョンを管理しています。

```bash
# FVM のインストール
dart pub global activate fvm

# Flutter バージョンのインストールと設定
fvm install 3.29.0
fvm use 3.29.0
```

### 3. 依存関係のインストール

```bash
fvm flutter pub get
```

### 4. 多言語化ファイルの生成

```bash
fvm flutter gen-l10n
```

## デモアプリの実行

サンプルファイルを含むデモアプリを実行できます。

```bash
fvm flutter run
```

## 実際の使用例

### CI/CD パイプラインでの使用

```yaml
# GitHub Actions
- name: Setup FVM
  uses: kuhnroyal/flutter-fvm-config-action@v1

- name: Check Japanese hardcoded strings
  run: fvm dart run tools/find_japanese_hardcoded_strings.dart

- name: Check ARB key consistency
  run: fvm dart run tools/check_arb_keys.dart
```

## スクリプトを使った品質チェック

```bash
# 日本語ハードコード文字列をチェック
fvm dart run tools/find_japanese_hardcoded_strings.dart

# ARBキーの整合性をチェック
fvm dart run tools/check_arb_keys.dart
```

## 貢献

このプロジェクトへの貢献を歓迎します！以下の方法でご参加ください。

1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'feat: Add amazing feature'`)
4. ブランチをプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。

## 技術記事

このツールに関する詳細な技術記事は[こちら](https://zenn.dev/tks_00/articles/07cfa8532abc8b)をご覧ください。

