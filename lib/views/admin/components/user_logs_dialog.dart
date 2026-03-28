import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/admin_providers.dart';
import 'admin_theme.dart';

class UserLogsDialog extends ConsumerWidget {
  const UserLogsDialog({super.key, required this.userDoc});

  final DocumentSnapshot userDoc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data     = userDoc.data() as Map<String, dynamic>;
    final userName = data['name'] as String? ?? '不明';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ヘッダー ──
            Row(
              children: [
                Expanded(
                  child: Text('$userName のアクセスログ',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textMain)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AdminColors.textSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── ログテーブル ──
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ref
                    .read(adminUsersViewModelProvider)
                    .watchAccessLogs(userDoc.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AdminColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('エラー: ${snapshot.error}',
                            style: const TextStyle(
                                color: AdminColors.red, fontSize: 12)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('ログがありません',
                          style: TextStyle(color: AdminColors.textSub)),
                    );
                  }

                  final logs = snapshot.data!.docs;
                  return SingleChildScrollView(
                    child: Table(
                      border: const TableBorder(
                        horizontalInside:
                            BorderSide(color: AdminColors.border),
                        bottom: BorderSide(color: AdminColors.border),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(3),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        // ヘッダー行
                        TableRow(
                          decoration:
                              const BoxDecoration(color: Color(0xFFF8F9FC)),
                          children: ['管理者', '操作', '詳細', '日時']
                              .map((h) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Text(h,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AdminColors.textSub,
                                            letterSpacing: 0.5)),
                                  ))
                              .toList(),
                        ),
                        // データ行
                        ...logs.map((log) {
                          final l  = log.data() as Map<String, dynamic>;
                          final ts = l['accessedAt'] as Timestamp?;
                          final dt = ts != null
                              ? '${ts.toDate().year}/${ts.toDate().month.toString().padLeft(2, '0')}/${ts.toDate().day.toString().padLeft(2, '0')} ${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
                              : '—';
                          return TableRow(children: [
                            _logCell(l['adminName'] as String? ?? '—',
                                bold: true),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AdminColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l['action'] as String? ?? '—',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AdminColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                            _logCell(l['detail'] as String? ?? '—'),
                            _logCell(dt, color: AdminColors.textSub),
                          ]);
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _logCell(String text,
          {bool bold = false, Color? color}) =>
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: color ?? AdminColors.textMain,
          ),
        ),
      );
}
