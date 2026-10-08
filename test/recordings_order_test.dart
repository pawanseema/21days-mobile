import 'package:flutter_test/flutter_test.dart';
import 'package:twenty_one_days/models/year_recordings.dart';

SessionVideo _video(String id, DateTime? publishedAt) {
  return SessionVideo(
    videoId: id,
    title: id,
    youtubeWatchUrl: 'https://www.youtube.com/watch?v=$id',
    publishedAt: publishedAt,
  );
}

void main() {
  test('orders session videos newest first', () {
    final older = DateTime(2026, 1, 2);
    final newer = DateTime(2026, 3, 4);
    final ordered = videosNewestFirst([
      _video('old', older),
      _video('undated', null),
      _video('new', newer),
    ]);

    expect(ordered.map((video) => video.videoId), ['new', 'old', 'undated']);
  });
}
