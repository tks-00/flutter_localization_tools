/// ARBファイルのキー比較ツール
///
/// 2つのARBファイル（英語、日本語）のキーを比較し、漏れをチェックします。
///
/// 使用方法:
///   dart tools/check_arb_keys.dart
///   または
///   ./tools/check_arb_keys.dart
///
/// このスクリプトは以下をチェックします：
/// - 各言語のキー数
/// - 欠落しているキー
/// - 一部の言語にのみ存在するキー
/// - 各言語固有のキー

library;

import 'dart:convert';
import 'dart:io';

/// ARBファイルを読み込み、Mapとして返す
Future<Map<String, dynamic>> loadArbFile(String filePath) async {
  final file = File(filePath);
  final contents = await file.readAsString(encoding: utf8);
  return jsonDecode(contents) as Map<String, dynamic>;
}

/// ARBデータからキーを抽出（@で始まるメタデータキーを除く）
Set<String> extractKeys(Map<String, dynamic> arbData) {
  return arbData.keys
      .where((key) => !key.startsWith('@') && key != '@@locale')
      .toSet();
}

Future<void> main() async {
  try {
    // ARBファイルのパス
    const basePath = 'lib/l10n';
    final files = {'en': '$basePath/app_en.arb', 'ja': '$basePath/app_ja.arb'};

    // 各ファイルからキーを抽出
    final arbKeys = <String, Set<String>>{};

    for (final entry in files.entries) {
      final lang = entry.key;
      final filePath = entry.value;

      final file = File(filePath);
      if (await file.exists()) {
        final arbData = await loadArbFile(filePath);
        final keys = extractKeys(arbData);
        arbKeys[lang] = keys;
        stdout.writeln('${lang.toUpperCase()}: ${keys.length}個のキー');
      } else {
        stderr.writeln('ファイルが見つかりません: $filePath');
        return;
      }
    }

    stdout.writeln('\n${'=' * 60}');

    // 全言語のキーを統合
    final allKeys = <String>{};
    for (final keys in arbKeys.values) {
      allKeys.addAll(keys);
    }

    stdout.writeln('合計キー数: ${allKeys.length}');

    // 各言語で漏れているキーをチェック
    stdout.writeln('\n${'=' * 60}');
    stdout.writeln('言語別の不足キー:');
    stdout.writeln('=' * 60);

    for (final lang in ['en', 'ja']) {
      final currentKeys = arbKeys[lang]!;
      final missingKeys = allKeys.difference(currentKeys);

      if (missingKeys.isNotEmpty) {
        stdout.writeln(
          '\n${lang.toUpperCase()} に不足している${missingKeys.length}個のキー:',
        );
        final sortedMissing = missingKeys.toList()..sort();
        for (final key in sortedMissing) {
          stdout.writeln('  - $key');
        }
      } else {
        stdout.writeln('\n${lang.toUpperCase()}: 不足キーなし ✓');
      }
    }

    // 他の言語には存在するが特定の言語にのみ存在しないキーをチェック
    stdout.writeln('\n${'=' * 60}');
    stdout.writeln('一部の言語にのみ存在するキー:');
    stdout.writeln('=' * 60);

    final sortedAllKeys = allKeys.toList()..sort();

    for (final key in sortedAllKeys) {
      final languagesWithKey = <String>[];

      for (final entry in arbKeys.entries) {
        final lang = entry.key;
        final keys = entry.value;
        if (keys.contains(key)) {
          languagesWithKey.add(lang.toUpperCase());
        }
      }

      // すべての言語（2つ）に存在しない場合
      if (languagesWithKey.length < 2) {
        const allLanguages = {'EN', 'JA'};
        final missingLangs = allLanguages.difference(languagesWithKey.toSet());

        stdout.writeln('\n\'$key\':');
        stdout.writeln('  存在する言語: ${languagesWithKey.join(', ')}');
        final sortedMissingLangs = missingLangs.toList()..sort();
        stdout.writeln('  不足している言語: ${sortedMissingLangs.join(', ')}');
      }
    }

    // 追加の統計情報
    stdout.writeln('\n${'=' * 60}');
    stdout.writeln('詳細統計:');
    stdout.writeln('=' * 60);

    // 各言語のユニークなキー（他の言語にないキー）
    for (final lang in ['en', 'ja']) {
      final currentKeys = arbKeys[lang]!;
      final otherKeys = <String>{};

      for (final entry in arbKeys.entries) {
        if (entry.key != lang) {
          otherKeys.addAll(entry.value);
        }
      }

      final uniqueKeys = currentKeys.difference(otherKeys);
      if (uniqueKeys.isNotEmpty) {
        stdout.writeln('\n${lang.toUpperCase()} 固有キー (${uniqueKeys.length}個):');
        final sortedUnique = uniqueKeys.toList()..sort();
        for (final key in sortedUnique) {
          stdout.writeln('  - $key');
        }
      }
    }
  } catch (e, stackTrace) {
    stderr.writeln('エラーが発生しました: $e');
    stderr.writeln('スタックトレース: $stackTrace');
    exit(1);
  }
}
