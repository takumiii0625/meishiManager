import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'components/admin_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_dashboard_providers.dart';

class AdminDashboardContent extends ConsumerWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(dashboardUsersStreamProvider);
    final logsAsync  = ref.watch(dashboardAccessLogsStreamProvider);
    final vm         = ref.watch(adminDashboardViewModelProvider);

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ダッシュボード',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textMain,
                    letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text('管理画面の概要',
                style: TextStyle(fontSize: 13, color: AdminColors.textSub)),
            const SizedBox(height: 28),

            usersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AdminColors.primary)),
              error: (e, _) => Center(
                  child: Text('エラー: $e',
                      style: const TextStyle(color: AdminColors.red))),
              data: (snapshot) {
                final users      = snapshot.docs;
                final total      = users.length;
                final active     = users.where((d) =>
                    (d.data() as Map)['status'] == 'active').length;
                final suspended  = users.where((d) =>
                    (d.data() as Map)['status'] == 'suspended').length;
                final thisMonth  = vm.calcThisMonthRegistrations(users);
                final monthly    = vm.calcMonthlyRegistrations(users);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 統計カード
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatCard(
                            label: '総ユーザー数',
                            value: '$total',
                            accent: AdminColors.primary,
                            bg: AdminColors.primaryLight,
                            icon: Icons.people_outline,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: '有効ユーザー',
                            value: '$active',
                            sub: total > 0
                                ? '${(active / total * 100).toStringAsFixed(1)}%'
                                : '0%',
                            accent: AdminColors.green,
                            bg: AdminColors.greenBg,
                            icon: Icons.check_circle_outline,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: '停止中',
                            value: '$suspended',
                            sub: total > 0
                                ? '${(suspended / total * 100).toStringAsFixed(1)}%'
                                : '0%',
                            accent: AdminColors.red,
                            bg: AdminColors.redBg,
                            icon: Icons.pause_circle_outline,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: '今月の新規登録',
                            value: '$thisMonth',
                            accent: AdminColors.purple,
                            bg: AdminColors.purpleBg,
                            icon: Icons.person_add_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // グラフ + アクセスログ
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _MonthlyChart(monthly: monthly),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: logsAsync.when(
                              loading: () =>
                                  const _LogCard(logs: []),
                              error: (_, __) =>
                                  const _LogCard(logs: []),
                              data: (snap) =>
                                  _LogCard(logs: snap.docs),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
// 統計カード
// ----------------------------------------------------------------
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.bg,
    required this.icon,
    this.sub,
  });

  final String   label;
  final String   value;
  final String?  sub;
  final Color    accent;
  final Color    bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8)
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Text(value,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: accent)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AdminColors.textSub)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!,
                      style: TextStyle(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w600)),
                ] else
                  const SizedBox(height: 13),
              ],
            ),
            Positioned(
              right: 0,
              top: 12,
              child: Icon(icon,
                  size: 32, color: accent.withOpacity(0.15)),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
// 月別グラフ
// ----------------------------------------------------------------
class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.monthly});

  final Map<String, int> monthly;

  @override
  Widget build(BuildContext context) {
    final entries = monthly.entries.toList();
    final maxVal  = entries.isEmpty
        ? 1
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('月別ユーザー登録数',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textMain)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final isLatest = entry == entries.last;
                final ratio   = maxVal > 0
                    ? entry.value / maxVal
                    : 0.0;
                final label   = entry.key.substring(5);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.value > 0)
                          Text('${entry.value}',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isLatest
                                      ? AdminColors.primary
                                      : AdminColors.textSub)),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: 120 * ratio,
                          decoration: BoxDecoration(
                            color: isLatest
                                ? AdminColors.primary
                                : const Color(0xFFC7D0FA),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${label}月',
                            style: const TextStyle(
                                fontSize: 9, color: AdminColors.textSub)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// アクセスログカード
// ----------------------------------------------------------------
class _LogCard extends ConsumerWidget {
  const _LogCard({required this.logs});

  final List<QueryDocumentSnapshot> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(adminDashboardViewModelProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('最近のアクセスログ',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textMain)),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('ログがありません',
                    style: TextStyle(fontSize: 13, color: AdminColors.textSub)),
              ),
            )
          else
            ...logs.map((log) {
              final l       = log.data() as Map<String, dynamic>;
              final action  = l['action'] as String? ?? '';
              final ts      = l['accessedAt'] as Timestamp?;
              final dt      = ts?.toDate();
              final timeStr = dt != null ? vm.timeAgo(dt) : '—';
              final adminName = l['adminName'] as String? ?? '管理者';
              final detail  = l['detail'] as String? ?? '';

              Color iconBg;
              Color iconColor;
              IconData iconData;
              switch (action) {
                case 'view_cards':
                  iconBg = AdminColors.primaryLight; iconColor = AdminColors.primary;
                  iconData = Icons.style_outlined; break;
                case 'edit_user':
                  iconBg = AdminColors.greenBg; iconColor = AdminColors.green;
                  iconData = Icons.edit_outlined; break;
                case 'delete_user':
                  iconBg = AdminColors.redBg; iconColor = AdminColors.red;
                  iconData = Icons.delete_outline; break;
                case 'create_user':
                  iconBg = AdminColors.purpleBg; iconColor = AdminColors.purple;
                  iconData = Icons.person_add_outlined; break;
                default:
                  iconBg = const Color(0xFFF2F3F7);
                  iconColor = AdminColors.textMid;
                  iconData = Icons.history;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconData, size: 16, color: iconColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(detail.isNotEmpty
                              ? detail : vm.actionLabel(action),
                              style: const TextStyle(
                                  fontSize: 12, color: AdminColors.textMain)),
                          const SizedBox(height: 2),
                          Text('$adminName · $timeStr',
                              style: const TextStyle(
                                  fontSize: 11, color: AdminColors.textSub)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
