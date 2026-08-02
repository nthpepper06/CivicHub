import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

Future<bool> showAiSuggestionPreviewDialog({
  required BuildContext context,
  required String title,
  required String suggestion,
  String? metadata,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                suggestion,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              if (metadata != null && metadata.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(metadata, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accept'),
          ),
        ],
      );
    },
  );
  return accepted ?? false;
}

Future<void> showAiImageContextDialog({
  required BuildContext context,
  required String suggestion,
  double? confidence,
}) async {
  final confidenceLabel = confidence == null
      ? null
      : 'Confidence: ${(confidence * 100).round()}%';
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Image context'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                suggestion,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              if (confidenceLabel != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  confidenceLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      );
    },
  );
}
