// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import '../../models/recording_model.dart';

Widget? buildYoutubeEmbed(RecordingResult result) {
  final videoId = result.videoId.isNotEmpty
      ? result.videoId
      : _idFromUrl(result.url);
  if (videoId == null || videoId.isEmpty) return null;

  final start = result.startSeconds;
  final viewType =
      'yt-embed-$videoId-$start-${DateTime.now().microsecondsSinceEpoch}';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..src =
          'https://www.youtube.com/embed/$videoId?start=$start&autoplay=1&playsinline=1&rel=0'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true
      ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
    return iframe;
  });

  return HtmlElementView(viewType: viewType);
}

String? _idFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  return uri.queryParameters['v'];
}
