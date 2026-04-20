import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/ticket_model.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../../core/utils/date_formatter.dart';

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const TicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/tickets/${ticket.id}'),
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: ticket.status),
                ],
              ),
              if (ticket.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  ticket.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  PriorityBadge(priority: ticket.priority),
                  const Spacer(),
                  if (ticket.creatorName != null)
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          ticket.creatorName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.timeAgo(ticket.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
