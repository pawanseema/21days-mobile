import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/mentor_provider.dart';
import '../../theme/app_theme.dart';

/// Mentor tab — assigned mentor profile + request action.
class MentorScreen extends StatelessWidget {
  const MentorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MentorProvider>();
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final mentor = state.mentor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text('Your Assigned Mentor', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'A mentor walks with you through the 21 days — answering questions '
          'and keeping your meditation practice light.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (mentor != null)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.mist),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.mist,
                  child: Text(
                    mentor.name.characters.first.toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.deepTeal,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(mentor.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(
                  mentor.bio,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                if (mentor.specialties.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: mentor.specialties
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            backgroundColor: AppColors.apricotMist,
                            side: BorderSide.none,
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.warmOrange,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (mentor.email != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    mentor.email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.deepTeal,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.apricotMist.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.mist),
            ),
            child: Text(
              state.requestPending
                  ? 'Your request is pending. A mentor will reach out soon.'
                  : 'You do not have an assigned mentor yet.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: state.isRequesting || state.requestPending
              ? null
              : () => state.requestMentor(),
          icon: state.isRequesting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.handshake_outlined),
          label: Text(
            state.requestPending ? 'Request pending' : 'Request Mentor',
          ),
        ),
        if (state.message != null) ...[
          const SizedBox(height: 12),
          Text(
            state.message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.deepTeal,
            ),
          ),
        ],
      ],
    );
  }
}
