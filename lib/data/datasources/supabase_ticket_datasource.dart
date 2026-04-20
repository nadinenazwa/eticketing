import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/ticket_model.dart';
import '../../domain/models/comment_model.dart';
import '../../core/constants/supabase_constants.dart';

class SupabaseTicketDatasource {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ── TICKETS ──────────────────────────────────────────────

  Future<List<TicketModel>> getTickets({String? userId}) async {
    List<Map<String, dynamic>> data;

    if (userId != null) {
      data = await _client
          .from(SupabaseConstants.ticketsTable)
          .select('*, profiles!created_by(full_name), assignee:profiles!assigned_to(full_name)')
          .eq('created_by', userId)
          .order('created_at', ascending: false);
    } else {
      data = await _client
          .from(SupabaseConstants.ticketsTable)
          .select('*, profiles!created_by(full_name), assignee:profiles!assigned_to(full_name)')
          .order('created_at', ascending: false);
    }

    return data.map((e) => TicketModel.fromJson(e)).toList();
  }

  Future<TicketModel> getTicketById(String id) async {
    final data = await _client
        .from(SupabaseConstants.ticketsTable)
        .select('*, profiles!created_by(full_name), assignee:profiles!assigned_to(full_name)')
        .eq('id', id)
        .single();
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String priority,
    required String createdBy,
    Uint8List? attachmentBytes,
    String? fileName,
  }) async {
    String? attachmentUrl;

    if (attachmentBytes != null && fileName != null) {
      final uploadFileName = '${_uuid.v4()}_$fileName';
      await _client.storage
          .from(SupabaseConstants.attachmentsBucket)
          .uploadBinary(uploadFileName, attachmentBytes);
      attachmentUrl = _client.storage
          .from(SupabaseConstants.attachmentsBucket)
          .getPublicUrl(uploadFileName);
    }

    final data = await _client
        .from(SupabaseConstants.ticketsTable)
        .insert({
          'title':          title,
          'description':    description,
          'priority':       priority,
          'created_by':     createdBy,
          'status':         'open',
          'attachment_url': attachmentUrl,
        })
        .select()
        .single();

    return TicketModel.fromJson(data);
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _client
        .from(SupabaseConstants.ticketsTable)
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', ticketId);
  }

  Future<void> assignTicket(String ticketId, String assigneeId) async {
    await _client
        .from(SupabaseConstants.ticketsTable)
        .update({'assigned_to': assigneeId, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', ticketId);
  }

  // ── STATISTIK ─────────────────────────────────────────────

  Future<Map<String, int>> getTicketStats({String? userId}) async {
    List<Map<String, dynamic>> data;

    if (userId != null) {
      data = await _client
          .from(SupabaseConstants.ticketsTable)
          .select('status')
          .eq('created_by', userId);
    } else {
      data = await _client
          .from(SupabaseConstants.ticketsTable)
          .select('status');
    }

    final stats = <String, int>{
      'total':       data.length,
      'open':        0,
      'in_progress': 0,
      'resolved':    0,
      'closed':      0,
    };

    for (final item in data) {
      final status = item['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  // ── KOMENTAR ──────────────────────────────────────────────

  Future<List<CommentModel>> getComments(String ticketId) async {
    final data = await _client
        .from(SupabaseConstants.commentsTable)
        .select('*, profiles!author_id(full_name)')
        .eq('ticket_id', ticketId)
        .order('created_at');
    return (data as List).map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CommentModel> addComment({
    required String ticketId,
    required String authorId,
    required String content,
  }) async {
    final data = await _client
        .from(SupabaseConstants.commentsTable)
        .insert({
          'ticket_id': ticketId,
          'author_id': authorId,
          'content':   content,
        })
        .select('*, profiles!author_id(full_name)')
        .single();
    return CommentModel.fromJson(data);
  }
}
