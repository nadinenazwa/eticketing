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

  Future<void> _updateStatus(String newStatus) async {
    try {
      await ref.read(ticketActionsProvider).updateStatus(widget.ticketId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status berhasil diperbarui'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.danger),
        );
      }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ubah Status',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...statuses.map((s) => ListTile(
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: AppTheme.statusColor(s),
                  ),
                  title: Text(AppTheme.statusLabel(s)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateStatus(s);
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user         = ref.watch(authProvider).value;
    final ticketAsync  = ref.watch(ticketDetailProvider(widget.ticketId));
    final commentsAsync = ref.watch(commentsProvider(widget.ticketId));
    final theme        = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detail Tiket'),
        actions: [
          if (user?.isHelpdesk == true)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => ticketAsync.whenData(
                    (_) => _showStatusPicker(context),
                  ),
            ),
        ],
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
                                child: Text(
                                  ticket.title,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              StatusBadge(status: ticket.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (ticket.description.isNotEmpty) ...[
                            Text(
                              ticket.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const Divider(),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.flag_outlined,
                            label: 'Prioritas',
                            value: AppTheme.priorityLabel(ticket.priority),
                            valueColor: AppTheme.priorityColor(ticket.priority),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'Dibuat oleh',
                            value: ticket.creatorName ?? '-',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.support_agent,
                            label: 'Ditangani',
                            value: ticket.assigneeName ?? 'Belum ditugaskan',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.access_time,
                            label: 'Dibuat',
                            value: DateFormatter.format(ticket.createdAt),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.update,
                            label: 'Diperbarui',
                            value: DateFormatter.format(ticket.updatedAt),
                          ),
                          if (ticket.attachmentUrl != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.attachment,
                                    size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text('Lampiran',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                ticket.attachmentUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                      child: Icon(Icons.broken_image_outlined)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Komentar header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      'Komentar & Diskusi',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),

                  // Komentar list
                  commentsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Gagal memuat komentar: $e'),
                    ),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Belum ada komentar. Tulis komentar pertama!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.45),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: comments
                            .map((c) => CommentTile(
                                  comment: c,
                                  isMe: c.authorId == user?.id,
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Input komentar
            Container(
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sendingComment
                      ? const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2.5)),
                        )
                      : IconButton.filled(
                          onPressed: _sendComment,
                          icon: const Icon(Icons.send_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.45)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
