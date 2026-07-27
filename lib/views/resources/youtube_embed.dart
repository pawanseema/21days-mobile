import 'package:flutter/widgets.dart';

import '../../models/recording_model.dart';
import 'youtube_embed_stub.dart'
    if (dart.library.html) 'youtube_embed_web.dart' as embed;

/// Platform YouTube embed (iframe on web, null on VM — use [VideoPlayerScreen]).
Widget? buildYoutubeEmbed(RecordingResult result) =>
    embed.buildYoutubeEmbed(result);
