class SupabaseConstants {
  // Table names
  static const String profilesTable = 'profiles';
  static const String ticketsTable  = 'tickets';
  static const String commentsTable = 'comments';

  // Storage buckets
  static const String attachmentsBucket = 'attachments';

  // Ticket status
  static const String statusOpen       = 'open';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved   = 'resolved';
  static const String statusClosed     = 'closed';

  // Ticket priority
  static const String priorityLow    = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh   = 'high';

  // User roles
  static const String roleUser     = 'user';
  static const String roleHelpdesk = 'helpdesk';
  static const String roleAdmin    = 'admin';
}
