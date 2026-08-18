/// Static wisdom / meditation topic for the Wisdom tab.
class WisdomTopic {
  const WisdomTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    this.accentLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final String body;
  final String? accentLabel;

  factory WisdomTopic.fromJson(Map<String, dynamic> json) {
    final accent = json['accent_label']?.toString().trim();
    return WisdomTopic(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      accentLabel: (accent == null || accent.isEmpty) ? null : accent,
    );
  }
}

/// Payload from `GET /api/wisdom/topics`.
class WisdomTopicsResponse {
  const WisdomTopicsResponse({
    required this.heading,
    required this.subtitle,
    required this.topics,
  });

  final String heading;
  final String subtitle;
  final List<WisdomTopic> topics;

  factory WisdomTopicsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['topics'];
    final topics = <WisdomTopic>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          topics.add(WisdomTopic.fromJson(item));
        } else if (item is Map) {
          topics.add(WisdomTopic.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return WisdomTopicsResponse(
      heading: json['heading']?.toString().trim().isNotEmpty == true
          ? json['heading'].toString()
          : 'Meditation wisdom',
      subtitle: json['subtitle']?.toString() ?? '',
      topics: topics,
    );
  }
}

/// Bundled fallback if `GET /api/wisdom/topics` is unreachable.
class WisdomCatalog {
  WisdomCatalog._();

  static const List<WisdomTopic> topics = [
    WisdomTopic(
      id: 'origin-of-sahaja-yoga',
      title: 'The origin of Sahaja Yoga',
      subtitle: 'Shri Mataji and the gift of Self-Realization',
      accentLabel: 'Origins',
      body:
          'Sahaja Yoga was founded in 1970 by Nirmala Srivastava (1923-2011), '
          'known by millions of Her spiritual followers as Shri Mataji '
          'Nirmala Devi. Shri Mataji discovered a technique to awaken the '
          'Kundalini energy within human beings. She dedicated Her life to '
          'teaching people of all nationalities, races, and religious '
          'backgrounds how to use Sahaja Yoga to better theirs. She envisioned '
          'the regular practice of Sahaja Yoga producing evolved societies, '
          'where people lead joyful, balanced lives.',
    ),
    WisdomTopic(
      id: 'subtle-system',
      title: 'The Subtle System',
      subtitle: 'Channels of awareness within',
      accentLabel: 'Foundation',
      body:
          'The subtle system is the network of energy centers (chakras) and channels (nadis) '
          'along the central nervous system through which our Kundalini flows. Sahaja Yoga '
          'helps you learn to feel, understand and ultimately use your own subtle system to '
          'achieve Self-Realization.',
    ),
    WisdomTopic(
      id: 'chakras',
      title: 'Chakras',
      subtitle: 'Seven centers of integration',
      accentLabel: 'Inner map',
      body:
          'There are seven main chakras (energy centers) located along the '
          'spine. They are the fulcrums that control most aspects of our '
          'physical, mental and spiritual lives. Chakras are located at the '
          'sites of our main nerve plexuses.\n\n'
          'Often difficulties in life can be traced to imbalances or '
          'blockages in one or more chakras. Chakras are connected by nadis '
          '(or channels). When the Kundalini rises and nourishes the chakras, '
          'our body automatically becomes dynamic, creative and integrated.\n\n'
          'Each chakra has a physical manifestation in your nervous system '
          'and is responsible for the smooth functioning of part of your '
          'physiology. Additionally, each chakra has subtle qualities, an '
          'essence that can influence your character and personality.',
    ),
    WisdomTopic(
      id: 'kundalini',
      title: 'Kundalini',
      subtitle: 'The residual power of pure desire',
      accentLabel: 'Awakening',
      body:
          'Your inner energy, or Kundalini, is a soothing spiritual energy '
          'that lies dormant at the base of the spine. It is an expression '
          'of the pure desire to evolve and better ourselves, something we '
          'all possess. When awakened, it rises through the central channel, '
          'clearing and activating your chakras. It allows you to achieve '
          'your Self-Realization.',
    ),
    WisdomTopic(
      id: 'left-right-channels',
      title: 'Left & Right Channels',
      subtitle: 'Emotions, action, and balance',
      accentLabel: 'Balance',
      body:
          'The left channel relates to emotions and the past; the right to '
          'action and the future. Sahaja meditation clears both so the '
          'central channel — the present — can flow freely.',
    ),
    WisdomTopic(
      id: 'thoughtless-awareness',
      title: 'Thoughtless Awareness',
      subtitle: 'The state of meditation',
      accentLabel: 'Practice',
      body:
          'In thoughtless awareness the mind is silent yet alert. One watches '
          'without reacting, resting in the present. This is the natural '
          'state Sahaja Yoga makes available through Self-realization.',
    ),
    WisdomTopic(
      id: 'collective',
      title: 'The Collective',
      subtitle: 'Growing together in Spirit',
      accentLabel: 'Community',
      body:
          'Meditating with others amplifies the experience. Weekly live '
          'sessions, mentoring, and shared wisdom keep the attention clean '
          'and the heart open throughout the 21-day journey.',
    ),
  ];
}
