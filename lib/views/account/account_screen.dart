import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_controller.dart';
import '../../theme/app_palette.dart';

/// Account details, appearance picker, and App Store delete-account path.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final isGuest = auth.user?.isGuest == true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isGuest ? 'Leave guest session?' : 'Delete account?'),
        content: Text(
          isGuest
              ? 'This clears your local guest session on this device. '
                  'You can continue as guest again anytime.'
              : 'This permanently deletes your 21Days account and signs you out. '
                  'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: Text(isGuest ? 'Clear session' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await auth.deleteAccount();
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themes = context.watch<ThemeController>();
    final user = auth.user;
    final theme = Theme.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signed in as', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(
                    user?.isGuest == true
                        ? 'Guest'
                        : (user?.email.isNotEmpty == true
                            ? user!.email
                            : user?.displayName ?? 'Account'),
                    style: theme.textTheme.titleLarge,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Sign-in: ${user.authProvider.name}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appearance', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Try a color scheme. You can switch back anytime.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  ...themes.presets.map((palette) {
                    final selected = palette.id == themes.paletteId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: colors.ink,
                      ),
                      title: Text(palette.label),
                      trailing: _PaletteSwatches(palette: palette),
                      onTap: () => themes.setPaletteId(palette.id),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: auth.isBusy
                      ? null
                      : () async {
                          await auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red.shade700,
                  ),
                  title: Text(
                    user?.isGuest == true
                        ? 'Clear guest session'
                        : 'Delete account',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  subtitle: Text(
                    user?.isGuest == true
                        ? 'Required local cleanup for guest mode'
                        : 'Permanently remove your account (App Store)',
                  ),
                  onTap: auth.isBusy ? null : () => _confirmDelete(context),
                ),
              ],
            ),
          ),
          if (auth.isBusy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _PaletteSwatches extends StatelessWidget {
  const _PaletteSwatches({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Swatch(color: palette.pageBackground),
        _Swatch(color: palette.chromeBackground),
        _Swatch(color: palette.ink),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}
