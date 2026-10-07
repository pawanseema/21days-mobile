import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_check.dart';

/// On iPhone and Android, offers a store update once per published version.
///
/// Failures stay silent. The website never shows this.
class AppUpdateNotice extends StatefulWidget {
  const AppUpdateNotice({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateNotice> createState() => _AppUpdateNoticeState();
}

class _AppUpdateNoticeState extends State<AppUpdateNotice> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeOfferUpdate();
    });
  }

  Future<void> _maybeOfferUpdate() async {
    final offer = await AppUpdateCheck.lookup();
    if (!mounted || offer == null) return;

    final update = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('A new version is available'),
          content: const Text(
            'Update 21Days to install the latest version.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    if (!mounted || update == null) return;
    if (!update) {
      await AppUpdateCheck.dismiss(offer.latestVersion);
      return;
    }
    try {
      await launchUrl(offer.storeUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
