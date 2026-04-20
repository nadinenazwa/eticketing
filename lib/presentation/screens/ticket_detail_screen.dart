import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/comment_tile.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/constants/supabase_constants.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      await ref.read(ticketActionsProvider).addComment(widget.ticketId, text);
      _commentCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  void _showStatusPicker(BuildContext context) {
    final statuses = [
      SupabaseConstants.statusOpen,
      SupabaseConstants.statusInProgress,
      SupabaseConstants.statusResolved,
      SupabaseConstants.statusClosed,
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ubah Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...statuses.map((s) => ListTile(
              leading: Icon(Icons.circle, color: AppTheme.statusColor(s), size: 12),
              title: Text(AppTheme.statusLabel(s)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(ticketActionsProvider).updateStatus(widget.ticketId, s);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showAssigneePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final agentsAsync = ref.watch(agentsProvider);
          return agentsAsync.when(
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SizedBox(height: 200, child: Center(child: Text('Error: $e'))),
            data: (agents) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tugaskan Agen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  ...agents.map((a) => ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(a['full_name']),
                    subtitle: Text(a['role']),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(ticketActionsProvider).assignTicket(widget.ticketId, a['id'], a['full_name']);
                    },
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user         = ref.watch(authProvider).value;
    final ticketAsync  = ref.watch(ticketDetailProvider(widget.ticketId));
    final commentsAsync = ref.watch(commentsProvider(widget.ticketId));
    final logsAsync    = ref.watch(ticketLogsProvider(widget.ticketId));
    final theme        = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detail Tiket'),
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (ticket) => Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // Info card
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              GestureDetector(
                                onTap: user?.isHelpdesk == true ? () => _showStatusPicker(context) : null,
                                child: StatusBadge(status: ticket.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(ticket.description, style: theme.textTheme.bodyMedium),
                          const Divider(height: 32),
                          _InfoRow(icon: Icons.flag_outlined, label: 'Prioritas', value: AppTheme.priorityLabel(ticket.priority), valueColor: AppTheme.priorityColor(ticket.priority)),
                          const SizedBox(height: 8),
                          _InfoRow(icon: Icons.person_outline, label: 'Dibuat oleh', value: ticket.creatorName ?? '-'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _InfoRow(icon: Icons.support_agent, label: 'Ditangani', value: ticket.assigneeName ?? 'Belum ditugaskan')),
                              if (user?.role == 'admin' || user?.role == 'helpdesk')
                                TextButton(
                                  onPressed: () => _showAssigneePicker(context),
                                  child: const Text('Edit'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(icon: Icons.access_time, label: 'Dibuat', value: DateFormatter.format(ticket.createdAt)),
                        ],
                      ),
                    ),
                  ),

                  // Timeline / Logs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Riwayat Tiket', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  logsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const SizedBox(),
                    data: (logs) => ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (ctx, i) {
                        final log = logs[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Column(
                                children: [
                                  Icon(Icons.circle, size: 8, color: AppTheme.primary),
                                  SizedBox(height: 4),
                                  // logic for line
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: theme.textTheme.bodySmall,
                                        children: [
                                          TextSpan(text: log['author_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                          TextSpan(text: ' ${log['action']}'),
                                        ],
                                      ),
                                    ),
                                    Text(DateFormatter.format(DateTime.parse(log['created_at'])), style: theme.textTheme.labelSmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(height: 32),

                  // Komentar header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text('Komentar', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),

                  commentsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (comments) => Column(
                      children: comments.map((c) => CommentTile(comment: c, isMe: c.authorId == user?.id)).toList(),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),

            // Input komentar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(hintText: 'Tulis komentar...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sendingComment
                      ? const CircularProgressIndicator()
                      : IconButton.filled(onPressed: _sendComment, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),
        SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall)),
        Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 13))),
      ],
    );
  }
}
