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
}

/// Curated Sahaja Yoga topics shown on the Wisdom tab.
class WisdomCatalog {
  WisdomCatalog._();

  static const List<WisdomTopic> topics = [
    WisdomTopic(
      id: 'subtle-system',
      title: 'The Subtle System',
      subtitle: 'Channels of awareness within',
      accentLabel: 'Foundation',
      body:
          'Sahaja Yoga describes a living subtle system of energy channels '
          '(nadis) and energy centers (chakras). Through spontaneous awakening '
          'of Kundalini, one can feel the cool breeze of the Spirit and '
          'experience thoughtless awareness.',
    ),
    WisdomTopic(
      id: 'chakras',
      title: 'Chakras',
      subtitle: 'Seven centers of integration',
      accentLabel: 'Inner map',
      body:
          'Each chakra governs qualities such as innocence, creativity, '
          'peace, love, forgiveness, and pure attention. Meditation helps '
          'balance these centers so the attention becomes light and joyful.',
    ),
    WisdomTopic(
      id: 'kundalini',
      title: 'Kundalini',
      subtitle: 'The residual power of pure desire',
      accentLabel: 'Awakening',
      body:
          'Kundalini rests in the sacrum bone and rises through the central '
          'channel during Self-realization, granting the experience of the '
          'Spirit — a cool, peaceful vibration on the palms and above the head.',
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
