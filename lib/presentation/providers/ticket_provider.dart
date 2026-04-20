import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/supabase_ticket_datasource.dart';
import '../../domain/models/ticket_model.dart';
import '../../domain/models/comment_model.dart';
import 'auth_provider.dart';
import '../theme/app_theme.dart';

final ticketDatasourceProvider = Provider((_) => SupabaseTicketDatasource());

final ticketsProvider = FutureProvider.autoDispose<List<TicketModel>>((ref) async {
  final ds   = ref.read(ticketDatasourceProvider);
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  return ds.getTickets(userId: user.isHelpdesk ? null : user.id);
});

final ticketDetailProvider =
    FutureProvider.autoDispose.family<TicketModel, String>((ref, id) {
  return ref.read(ticketDatasourceProvider).getTicketById(id);
});

final commentsProvider =
    FutureProvider.autoDispose.family<List<CommentModel>, String>((ref, ticketId) {
  return ref.read(ticketDatasourceProvider).getComments(ticketId);
});

final ticketLogsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, ticketId) {
  return ref.read(ticketDatasourceProvider).getTicketLogs(ticketId);
});

final agentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(ticketDatasourceProvider).getAgents();
});

final ticketStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final ds   = ref.read(ticketDatasourceProvider);
  final user = ref.watch(authProvider).value;
  if (user == null) return {};
  return ds.getTicketStats(userId: user.isHelpdesk ? null : user.id);
});

final ticketActionsProvider = Provider((ref) => TicketActions(ref));

class TicketActions {
  final Ref _ref;
  TicketActions(this._ref);

  SupabaseTicketDatasource get _ds => _ref.read(ticketDatasourceProvider);

  Future<void> createTicket({
    required String title,
    required String description,
    required String priority,
    Uint8List? attachmentBytes,
    String? fileName,
  }) async {
    final user = _ref.read(authProvider).value;
    if (user == null) throw Exception('Belum login');
    await _ds.createTicket(
      title: title,
      description: description,
      priority: priority,
      createdBy: user.id,
      attachmentBytes: attachmentBytes,
      fileName: fileName,
    );
    _ref.invalidate(ticketsProvider);
    _ref.invalidate(ticketStatsProvider);
  }

  Future<void> updateStatus(String ticketId, String status) async {
    final user = _ref.read(authProvider).value;
    await _ds.updateTicketStatus(ticketId, status);
    if (user != null) {
      await _ds.addLog(ticketId, user.fullName, 'mengubah status menjadi ${AppTheme.statusLabel(status)}');
    }
    _ref.invalidate(ticketsProvider);
    _ref.invalidate(ticketDetailProvider(ticketId));
    _ref.invalidate(ticketLogsProvider(ticketId));
    _ref.invalidate(ticketStatsProvider);
  }

  Future<void> assignTicket(String ticketId, String assigneeId, String assigneeName) async {
    final user = _ref.read(authProvider).value;
    await _ds.assignTicket(ticketId, assigneeId);
    if (user != null) {
      await _ds.addLog(ticketId, user.fullName, 'menugaskan tiket kepada $assigneeName');
    }
    _ref.invalidate(ticketDetailProvider(ticketId));
    _ref.invalidate(ticketLogsProvider(ticketId));
  }

  Future<void> addComment(String ticketId, String content) async {
    final user = _ref.read(authProvider).value;
    if (user == null) throw Exception('Belum login');
    await _ds.addComment(
      ticketId: ticketId,
      authorId: user.id,
      content: content,
    );
    _ref.invalidate(commentsProvider(ticketId));
  }
}
