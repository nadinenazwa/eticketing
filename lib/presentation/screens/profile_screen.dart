import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart' show BottomNav;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(authProvider).value;
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        children: [
          // Avatar + nama
          Container(
            color: theme.appBarTheme.backgroundColor,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 10),
                _RoleBadge(role: user.role),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info tiles
          _SectionCard(
            title: 'Informasi Akun',
            children: [
              _InfoTile(
                icon: Icons.person_outline,
                label: 'Nama Lengkap',
                value: user.fullName,
              ),
              _InfoTile(
                icon: Icons.alternate_email,
                label: 'Username',
                value: user.username,
              ),
              _InfoTile(
                icon: Icons.shield_outlined,
                label: 'Role',
                value: user.role[0].toUpperCase() + user.role.substring(1),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Pengaturan
          _SectionCard(
            title: 'Pengaturan',
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Tema'),
                subtitle: Text(
                  themeMode == ThemeMode.system 
                    ? 'Sistem' 
                    : themeMode == ThemeMode.dark ? 'Gelap' : 'Terang'
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showThemeSelector(context, ref);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content:
                        const Text('Apakah kamu yakin ingin keluar dari akun?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.danger),
              label: const Text('Logout',
                  style: TextStyle(color: AppTheme.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final currentMode = ref.watch(themeProvider);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pilih Tema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                RadioListTile<ThemeMode>(
                  title: const Text('Terang'),
                  value: ThemeMode.light,
                  groupValue: currentMode,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).setThemeMode(val!);
                    Navigator.pop(ctx);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Gelap'),
                  value: ThemeMode.dark,
                  groupValue: currentMode,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).setThemeMode(val!);
                    Navigator.pop(ctx);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Sistem'),
                  value: ThemeMode.system,
                  groupValue: currentMode,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).setThemeMode(val!);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role) {
      case 'admin':    return AppTheme.danger;
      case 'helpdesk': return AppTheme.warning;
      default:         return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: TextStyle(
          color: _color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Card(child: Column(children: children)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      subtitle: Text(value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
    );
  }
}
