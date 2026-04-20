import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/supabase_ticket_datasource.dart';
import '../../domain/models/ticket_model.dart';
import '../../domain/models/comment_model.dart';
import 'auth_provider.dart';
import '../theme/app_theme.dart';

final ticketDatasourceProvider = Provider((_) => SupabaseTicketDatasource());

// Pagination State (NFR 4.1 Lazy Loading)
class TicketListState {
  final List<TicketModel> tickets;
  final int page;
  final bool isLoadingMore;
  final bool hasMore;

  TicketListState({
    required this.tickets,
    required this.page,
    required this.isLoadingMore,
    required this.hasMore,
  });

  TicketListState copyWith({
    List<TicketModel>? tickets,
    int? page,
    bool? isLoadingMore,
    bool? hasMore,
  }) => TicketListState(
    tickets: tickets ?? this.tickets,
    page: page ?? this.page,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
  );
}

class TicketListNotifier extends StateNotifier<AsyncValue<TicketListState>> {
  final SupabaseTicketDatasource _ds;
  final Ref _ref;

  TicketListNotifier(this._ds, this._ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final user = _ref.read(authProvider).value;
    try {
      final tickets = await _ds.getTickets(
        userId: user?.isHelpdesk == true ? null : user?.id,
        page: 0,
      );
      state = AsyncValue.data(TicketListState(
        tickets: tickets,
        page: 0,
        isLoadingMore: false,
        hasMore: tickets.length >= 10,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    final user = _ref.read(authProvider).value;
    
    try {
      final nextPage = current.page + 1;
      final moreTickets = await _ds.getTickets(
        userId: user?.isHelpdesk == true ? null : user?.id,
        page: nextPage,
      );
      
      state = AsyncValue.data(current.copyWith(
        tickets: [...current.tickets, ...moreTickets],
        page: nextPage,
        isLoadingMore: false,
        hasMore: moreTickets.length >= 10,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final ticketListProvider = StateNotifierProvider.autoDispose<TicketListNotifier, AsyncValue<TicketListState>>((ref) {
  return TicketListNotifier(ref.read(ticketDatasourceProvider), ref);
});

// Backward compatibility or for Dashboard
final ticketsProvider = Provider.autoDispose<AsyncValue<List<TicketModel>>>((ref) {
  return ref.watch(ticketListProvider).whenData((value) => value.tickets);
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
    _ref.read(ticketListProvider.notifier).refresh();
    _ref.invalidate(ticketStatsProvider);
  }

  Future<void> updateStatus(String ticketId, String status) async {
    final user = _ref.read(authProvider).value;
    await _ds.updateTicketStatus(ticketId, status);
    if (user != null) {
      await _ds.addLog(ticketId, user.fullName, 'mengubah status menjadi ${AppTheme.statusLabel(status)}');
    }
    _ref.read(ticketListProvider.notifier).refresh();
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
