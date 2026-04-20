import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../widgets/ticket_card.dart';
import 'dashboard_screen.dart' show BottomNav;

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  String _selectedStatus = 'all';

  final _statusFilters = const [
    ('all',        'Semua'),
    ('open',       'Open'),
    ('in_progress','In Progress'),
    ('resolved',   'Resolved'),
    ('closed',     'Closed'),
  ];

  @override
  Widget build(BuildContext context) {
    final user        = ref.watch(authProvider).value;
    final ticketsAsync = ref.watch(ticketsProvider);
    final theme       = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        actions: [
          if (user?.isHelpdesk == false)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push('/tickets/create'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _statusFilters.map((f) {
                final isSelected = _selectedStatus == f.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.$2),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = f.$1),
                    selectedColor:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ticketsProvider),
        child: ticketsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Error: $e')),
          data: (tickets) {
            final filtered = _selectedStatus == 'all'
                ? tickets
                : tickets
                    .where((t) => t.status == _selectedStatus)
                    .toList();

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 56,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada tiket',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => TicketCard(ticket: filtered[i]),
            );
          },
        ),
      ),
      floatingActionButton: user?.isHelpdesk == false
          ? FloatingActionButton(
              onPressed: () => context.push('/tickets/create'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}
