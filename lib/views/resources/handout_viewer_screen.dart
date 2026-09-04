import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/handout_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/api_messages.dart';
import '../../utils/layout_breakpoints.dart';
import '../../widgets/media_action_bar.dart';

/// In-app handout viewer (PDF-friendly WebView) for iOS/Android.
class HandoutViewerScreen extends StatefulWidget {
  const HandoutViewerScreen({super.key, required this.handout});

  final HandoutResult handout;

  @override
  State<HandoutViewerScreen> createState() => _HandoutViewerScreenState();
}

class _HandoutViewerScreenState extends State<HandoutViewerScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  String get _title {
    final title = widget.handout.title.trim();
    return title.isEmpty ? 'Handout' : title;
  }

  Uri get _sourceUri => Uri.parse(widget.handout.downloadUrl.trim());

  /// iOS WKWebView renders PDFs natively; Android WebView usually does not,
  /// so use Google's embedded viewer for short public PDFs.
  Uri get _loadUri {
    final source = _sourceUri;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Uri.https('docs.google.com', '/gview', {
        'embedded': 'true',
        'url': source.toString(),
      });
    }
    return source;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            // Ignore subframe / favicon noise; keep the main-frame failures.
            if (error.isForMainFrame == false) return;
            setState(() {
              _loading = false;
              _error = ApiMessages.requestFailed;
            });
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _controller.loadRequest(_loadUri);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiMessages.requestFailed;
      });
    }
  }

  Future<void> _openExternally() async {
    final ok =
        await launchUrl(_sourceUri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open that link.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comfortable = AppLayout.isComfortable(context);
    final scaled = comfortable
        ? AppTheme.comfortableDensity(theme)
        : theme;

    return Theme(
      data: scaled,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            MediaActionBar(
              url: widget.handout.downloadUrl,
              title: _title,
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_error == null) WebViewWidget(controller: _controller),
                  if (_loading && _error == null)
                    const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Material(
                color: context.colors.surface,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    AppLayout.space(context, 16),
                    AppLayout.space(context, 10),
                    AppLayout.space(context, 16),
                    AppLayout.space(context, 10),
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: context.colors.mist),
                    ),
                  ),
                  child: TextButton.icon(
                    onPressed: _openExternally,
                    icon: Icon(
                      Icons.open_in_new,
                      size: AppLayout.fontSize(context, 20),
                    ),
                    label: const Text('Open externally'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
