/// サンプル画面
///
/// このファイルには日本語のハードコーディングが含まれており、
/// find_japanese_hardcoded_strings.dart の動作確認に使用します。
/// また、ツールの使用方法も説明しています。

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SampleScreen extends StatelessWidget {
  const SampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // 日本語（検出される）
        title: const Text('ローカライゼーション ツール デモ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'フルーツリスト',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Gap(20),

            // 日本語でハードコードされた項目（これらが検出される）
            const Center(
              child: Column(
                children: [
                  Text('• りんご', style: TextStyle(fontSize: 18)),
                  Text('• ばなな', style: TextStyle(fontSize: 18)),
                  Text('• ぶどう', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            const Gap(20),

            const Text(
              '利用可能なツール',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Gap(12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. 日本語ハードコード文字列検出',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Gap(4),
                    const Text(
                      'dart run tools/find_japanese_hardcoded_strings.dart',
                    ),
                    const Gap(8),
                    const Text(
                      '2. ARBキー整合性チェック',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Gap(4),
                    const Text('dart run tools/check_arb_keys.dart'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
