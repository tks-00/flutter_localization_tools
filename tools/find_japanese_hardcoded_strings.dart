/// 日本語でハードコードされた文字列を検出するツール
///
/// このツールはFlutter/Dartプロジェクト内の日本語文字列リテラルを検出し、
/// 多言語化対応が必要な箇所を特定します。
///
/// 機能:
/// - ひらがな、カタカナ、漢字を含む文字列リテラルを検出
/// - コメント内の日本語は除外
/// - 既存のl10nファイルで管理されている文字列との重複をチェック
/// - ファイルパス、行番号、該当テキストを表示
///
/// 使用方法: `dart run tools/find_japanese_hardcoded_strings.dart`
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// 設定クラス
class JapaneseDetectorConfig {
  const JapaneseDetectorConfig({
    required this.targetDirectories,
    required this.excludePatterns,
    required this.excludeFiles,
    required this.includeComments,
    required this.l10nDirectory,
  });

  final List<String> targetDirectories;
  final List<String> excludePatterns;
  final List<String> excludeFiles;
  final bool includeComments;
  final String l10nDirectory;
}

/// デフォルト設定
const defaultConfig = JapaneseDetectorConfig(
  targetDirectories: ['lib/views'], // viewsディレクトリのみを対象にする
  excludePatterns: [
    '.g.dart',
    '.freezed.dart',
    '.mocks.dart',
    'generated_plugin_registrant.dart',
  ],
  excludeFiles: ['lib/l10n/', 'lib/gen/', 'lib/viewmodels/'],
  includeComments: false,
  l10nDirectory: 'lib/l10n',
);

/// 検出結果を格納するクラス
class JapaneseStringMatch {
  const JapaneseStringMatch({
    required this.filePath,
    required this.lineNumber,
    required this.content,
    required this.matchedText,
    required this.isInComment,
  });

  final String filePath;
  final int lineNumber;
  final String content;
  final String matchedText;
  final bool isInComment;

  @override
  String toString() {
    final relativePath = path.relative(filePath, from: Directory.current.path);
    final commentIndicator = isInComment ? ' [コメント内]' : '';
    return '$relativePath:$lineNumber$commentIndicator\n'
        '  → "$matchedText"\n'
        '  行: ${content.trim()}';
  }
}

/// 日本語文字を検出する正規表現パターン
class JapanesePatterns {
  // ひらがな: U+3040-U+309F
  static final hiragana = RegExp(r'[\u3040-\u309F]');

  // カタカナ: U+30A0-U+30FF
  static final katakana = RegExp(r'[\u30A0-\u30FF]');

  // CJK統合漢字: U+4E00-U+9FAF
  static final kanji = RegExp(r'[\u4E00-\u9FAF]');

  // 日本語文字全般
  static final japanese = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');

  // 文字列リテラル（シングルクォート）
  static final singleQuoteString = RegExp(r"'([^'\\]|\\.)*'");

  // 文字列リテラル（ダブルクォート）
  static final doubleQuoteString = RegExp(r'"([^"\\]|\\.)*"');

  // 生文字列リテラル（簡素化）
  static final rawString = RegExp(r'r"[^"]*"');

  // デバッグ出力文
  static final debugOutput = RegExp(r'debugPrint\s*\([^)]*\)');

  // 例外文
  static final exception = RegExp(r'Exception\s*\([^)]*\)');

  // 出力文
  static final outputStatement = RegExp(r'print\s*\([^)]*\)');

  // コメント（単行）
  static final singleLineComment = RegExp(r'//.*$', multiLine: true);

  // コメント（複数行）
  static final multiLineComment = RegExp(r'/\*.*?\*/', dotAll: true);
}

void main(List<String> args) async {
  stdout.writeln('🔍 日本語ハードコード文字列検出ツールを開始します...\n');

  final projectDir = Directory.current;

  // 引数で対象ディレクトリを指定可能に
  final targetDirs = args.isNotEmpty ? args : defaultConfig.targetDirectories;
  final config = JapaneseDetectorConfig(
    targetDirectories: targetDirs,
    excludePatterns: defaultConfig.excludePatterns,
    excludeFiles: defaultConfig.excludeFiles,
    includeComments: defaultConfig.includeComments,
    l10nDirectory: defaultConfig.l10nDirectory,
  );

  stdout.writeln('🎯 対象ディレクトリ: ${targetDirs.join(', ')}\n');

  // 既存のl10n文字列を読み込み
  final existingL10nStrings = await _loadExistingL10nStrings(projectDir);
  stdout.writeln('📚 既存のl10n文字列: ${existingL10nStrings.length}件読み込み完了\n');

  // Dartファイルを検索
  final dartFiles = await _findTargetDartFiles(projectDir, config);
  stdout.writeln('📁 対象Dartファイル: ${dartFiles.length}件\n');

  // 日本語文字列を検出
  final matches = <JapaneseStringMatch>[];
  var processedFiles = 0;

  for (final file in dartFiles) {
    // 除外対象ファイルかチェック
    if (_isExcludedFile(file.path)) {
      processedFiles++;
      continue; // 除外対象なのでスキップ
    }

    final fileMatches = await _detectJapaneseStrings(file);
    matches.addAll(fileMatches);
    processedFiles++;

    if (processedFiles % 10 == 0) {
      stdout.writeln('処理中... $processedFiles/${dartFiles.length}');
    }
  }

  // 結果を表示
  _displayResults(matches, existingL10nStrings);
}

/// 対象となるDartファイルを検索
Future<List<File>> _findTargetDartFiles(
  Directory projectDir,
  JapaneseDetectorConfig config,
) async {
  final files = <File>[];

  for (final targetDir in config.targetDirectories) {
    final dir = Directory(path.join(projectDir.path, targetDir));
    if (!dir.existsSync()) continue;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // 除外ファイルパターンをチェック
        final relativePath = path.relative(entity.path, from: projectDir.path);

        bool shouldExclude = false;
        for (final excludeFile in defaultConfig.excludeFiles) {
          if (relativePath.startsWith(excludeFile)) {
            shouldExclude = true;
            break;
          }
        }

        for (final excludePattern in config.excludePatterns) {
          if (relativePath.contains(excludePattern)) {
            shouldExclude = true;
            break;
          }
        }

        if (!shouldExclude) {
          files.add(entity);
        }
      }
    }
  }

  return files;
}

/// ファイル内の日本語文字列を検出
Future<List<JapaneseStringMatch>> _detectJapaneseStrings(File file) async {
  final matches = <JapaneseStringMatch>[];

  try {
    final content = await file.readAsString();
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      // コメントを処理
      if (!defaultConfig.includeComments) {
        final lineWithoutComments = _removeComments(line);
        final stringMatches = _extractJapaneseFromLine(
          lineWithoutComments,
          file.path,
          lineNumber,
          line,
        );
        matches.addAll(stringMatches);
      } else {
        // コメントも含めて検出
        final stringMatches = _extractJapaneseFromLine(
          line,
          file.path,
          lineNumber,
          line,
          includeComments: true,
        );
        matches.addAll(stringMatches);
      }
    }
  } catch (e) {
    stderr.writeln('ファイル読み込みエラー: ${file.path} - $e');
  }

  return matches;
}

/// 行からコメント、デバッグ出力、例外、出力文を除去
String _removeComments(String line) {
  // デバッグ出力を除去
  String cleanLine = line.replaceAll(JapanesePatterns.debugOutput, '');

  // 例外を除去
  cleanLine = cleanLine.replaceAll(JapanesePatterns.exception, '');

  // 出力文を除去
  cleanLine = cleanLine.replaceAll(JapanesePatterns.outputStatement, '');

  // 単行コメントを除去
  final commentIndex = cleanLine.indexOf('//');
  if (commentIndex >= 0) {
    // 文字列リテラル内のコメント記号は除去しない
    final beforeComment = cleanLine.substring(0, commentIndex);
    if (_isInsideStringLiteral(beforeComment, commentIndex)) {
      return cleanLine;
    }
    return beforeComment;
  }
  return cleanLine;
}

/// 指定位置が文字列リテラル内かどうかを判定
bool _isInsideStringLiteral(String text, int position) {
  int singleQuoteCount = 0;
  int doubleQuoteCount = 0;
  bool inEscape = false;

  for (int i = 0; i < position && i < text.length; i++) {
    if (inEscape) {
      inEscape = false;
      continue;
    }

    switch (text[i]) {
      case '\\':
        inEscape = true;
        break;
      case "'":
        singleQuoteCount++;
        break;
      case '"':
        doubleQuoteCount++;
        break;
    }
  }

  return (singleQuoteCount % 2 == 1) || (doubleQuoteCount % 2 == 1);
}

/// 行から日本語文字列を抽出
List<JapaneseStringMatch> _extractJapaneseFromLine(
  String line,
  String filePath,
  int lineNumber,
  String originalLine, {
  bool includeComments = false,
}) {
  final matches = <JapaneseStringMatch>[];

  // 文字列リテラルを検索
  final stringLiterals = <Match>[];
  stringLiterals.addAll(JapanesePatterns.singleQuoteString.allMatches(line));
  stringLiterals.addAll(JapanesePatterns.doubleQuoteString.allMatches(line));
  stringLiterals.addAll(JapanesePatterns.rawString.allMatches(line));

  for (final match in stringLiterals) {
    final stringContent = match.group(0)!;
    if (JapanesePatterns.japanese.hasMatch(stringContent)) {
      matches.add(
        JapaneseStringMatch(
          filePath: filePath,
          lineNumber: lineNumber,
          content: originalLine,
          matchedText: stringContent,
          isInComment: false,
        ),
      );
    }
  }

  // コメント内の日本語も検出する場合
  if (includeComments) {
    final commentMatches = <Match>[];
    commentMatches.addAll(JapanesePatterns.singleLineComment.allMatches(line));

    for (final match in commentMatches) {
      final commentContent = match.group(0)!;
      if (JapanesePatterns.japanese.hasMatch(commentContent)) {
        matches.add(
          JapaneseStringMatch(
            filePath: filePath,
            lineNumber: lineNumber,
            content: originalLine,
            matchedText: commentContent,
            isInComment: true,
          ),
        );
      }
    }
  }

  return matches;
}

/// 既存のl10n文字列を読み込み
Future<Set<String>> _loadExistingL10nStrings(Directory projectDir) async {
  final strings = <String>{};

  final l10nDir = Directory(
    path.join(projectDir.path, defaultConfig.l10nDirectory),
  );
  if (!l10nDir.existsSync()) {
    return strings;
  }

  await for (final entity in l10nDir.list()) {
    if (entity is File && entity.path.endsWith('.arb')) {
      try {
        final content = await entity.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        for (final value in json.values) {
          if (value is String && JapanesePatterns.japanese.hasMatch(value)) {
            strings.add(value);
          }
        }
      } catch (e) {
        stderr.writeln('ARBファイル読み込みエラー: ${entity.path} - $e');
      }
    }
  }

  return strings;
}

/// 結果を表示
void _displayResults(
  List<JapaneseStringMatch> matches,
  Set<String> existingL10nStrings,
) {
  if (matches.isEmpty) {
    stdout.writeln('✅ 日本語のハードコーディングは見つかりませんでした！');
    return;
  }

  stdout.writeln('🔍 検出結果: ${matches.length}件の日本語文字列が見つかりました\n');

  // ファイル別にグループ化
  final groupedMatches = <String, List<JapaneseStringMatch>>{};
  for (final match in matches) {
    final relativePath = path.relative(
      match.filePath,
      from: Directory.current.path,
    );
    groupedMatches.putIfAbsent(relativePath, () => []).add(match);
  }

  var totalCount = 0;

  for (final entry in groupedMatches.entries) {
    final filePath = entry.key;
    final fileMatches = entry.value;

    stdout.writeln('📄 $filePath (${fileMatches.length}件)');
    stdout.writeln('─' * 60);

    for (final match in fileMatches) {
      stdout.writeln('🔴 行${match.lineNumber}: ${match.matchedText}');
      stdout.writeln('   ${match.content.trim()}');
      stdout.writeln('');
      totalCount++;
    }
    stdout.writeln('');
  }

  // サマリー表示
  stdout.writeln('📊 サマリー');
  stdout.writeln('=' * 60);
  stdout.writeln('ハードコード文字列検出数: $totalCount件');

  if (totalCount > 0) {
    stderr.writeln('\n🚨 ${totalCount}件の日本語ハードコーディングが検出されました！');
    stderr.writeln('上記の箇所を確認して、l10nキーに置き換えてください。');
    exit(1);
  } else {
    stdout.writeln('\n✅ 日本語のハードコーディングは見つかりませんでした！');
  }
}

/// 除外対象ファイルパスのリスト
/// 後方互換性保持や設計上対応不要なファイルを指定
const _excludedFilePaths = [
  // 後方互換性のため対応不要
  'lib/views/widgets/order/order_constants.dart',
  'lib/views/widgets/sort/sort_order.dart',

  // 日本語以外では非表示のため対応不要
  'lib/views/screens/notification/components/notification_list_screen.dart',
  'lib/views/screens/notification/notification_list_screen.dart',
];

/// 指定したファイルが除外対象かチェック
bool _isExcludedFile(String filePath) {
  // 絶対パスを相対パスに変換
  final relativePath = path.relative(filePath, from: Directory.current.path);

  return _excludedFilePaths.any((excludedPath) {
    return relativePath == excludedPath || relativePath.endsWith(excludedPath);
  });
}
