import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/ticket_model.dart';
import '../../domain/models/comment_model.dart';
import '../../core/constants/supabase_constants.dart';

class SupabaseTicketDatasource {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ── TICKETS (Updated for Lazy Loading NFR 4.1) ─────────────────

  Future<List<TicketModel>> getTickets({
    String? userId, 
    int page = 0, 
    int pageSize = 10
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _client
        .from(SupabaseConstants.ticketsTable)
        .select('*, profiles!created_by(full_name), assignee:profiles!assigned_to(full_name)');

    if (userId != null) {
      query = query.eq('created_by', userId);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (data as List).map((e) => TicketModel.fromJson(e)).toList();
  }

  Future<TicketModel> getTicketById(String id) async {
    final data = await _client
        .from(SupabaseConstants.ticketsTable)
        .select('*, profiles!created_by(full_name), assignee:profiles!assigned_to(full_name)')
        .eq('id', id)
        .single();
    return TicketModel.fromJson(data);
  }

  // ... (Metode lain tetap sama)
  
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

  Future<void> addLog(String ticketId, String authorName, String action) async {
    await _client.from('ticket_logs').insert({
      'ticket_id': ticketId,
      'author_name': authorName,
      'action': action,
    });
  }

  Future<List<Map<String, dynamic>>> getTicketLogs(String ticketId) async {
    final data = await _client
        .from('ticket_logs')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, int>> getTicketStats({String? userId}) async {
    var query = _client.from(SupabaseConstants.ticketsTable).select('status');
    if (userId != null) query = query.eq('created_by', userId);
    
    final data = await query;
    final stats = {'total': data.length, 'open': 0, 'in_progress': 0, 'resolved': 0, 'closed': 0};
    for (final item in data) {
      final s = item['status'] as String;
      stats[s] = (stats[s] ?? 0) + 1;
    }
    return stats;
  }

  Future<List<Map<String, dynamic>>> getAgents() async {
    final data = await _client.from(SupabaseConstants.profilesTable).select('id, full_name, role').or('role.eq.helpdesk,role.eq.admin');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<CommentModel> addComment({required String ticketId, required String authorId, required String content}) async {
    final data = await _client.from(SupabaseConstants.commentsTable).insert({'ticket_id': ticketId, 'author_id': authorId, 'content': content}).select('*, profiles!author_id(full_name)').single();
    return CommentModel.fromJson(data);
  }

  Future<List<CommentModel>> getComments(String ticketId) async {
    final data = await _client.from(SupabaseConstants.commentsTable).select('*, profiles!author_id(full_name)').eq('ticket_id', ticketId).order('created_at');
    return (data as List).map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TicketModel> createTicket({required String title, required String description, required String priority, required String createdBy, Uint8List? attachmentBytes, String? fileName}) async {
    String? attachmentUrl;
    if (attachmentBytes != null && fileName != null) {
      final uploadFileName = '${_uuid.v4()}_$fileName';
      await _client.storage.from(SupabaseConstants.attachmentsBucket).uploadBinary(uploadFileName, attachmentBytes);
      attachmentUrl = _client.storage.from(SupabaseConstants.attachmentsBucket).getPublicUrl(uploadFileName);
    }
    final data = await _client.from(SupabaseConstants.ticketsTable).insert({'title': title, 'description': description, 'priority': priority, 'created_by': createdBy, 'status': 'open', 'attachment_url': attachmentUrl}).select().single();
    return TicketModel.fromJson(data);
  }
}
