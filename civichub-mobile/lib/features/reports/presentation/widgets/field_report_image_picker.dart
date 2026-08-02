import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_network_image.dart';

const int maxFieldReportImages = 5;

class FieldReportImage {
  FieldReportImage.local({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.bytes,
  }) : url = null;

  FieldReportImage.remote({required this.id, required this.url})
    : assert(url != null),
      fileName = _fileNameFromUrl(url!),
      contentType = 'image/*',
      bytes = null;

  final String id;
  final String fileName;
  final String contentType;
  final Uint8List? bytes;
  final String? url;

  bool get isLocal => bytes != null;

  static String _fileNameFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments;
    if (segments == null || segments.isEmpty || segments.last.isEmpty) {
      return 'Attached image';
    }
    return segments.last;
  }
}

class FieldReportImagePicker extends StatelessWidget {
  const FieldReportImagePicker({
    required this.images,
    required this.enabled,
    required this.uploading,
    required this.onTakePhoto,
    required this.onChooseGallery,
    required this.onRemove,
    required this.onReplace,
    required this.onMoveUp,
    required this.onMoveDown,
    this.errorMessage,
    super.key,
  });

  final List<FieldReportImage> images;
  final bool enabled;
  final bool uploading;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseGallery;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onReplace;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final canAdd =
        enabled && !uploading && images.length < maxFieldReportImages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: 'Take Photo',
              icon: Icons.photo_camera_outlined,
              variant: AppButtonVariant.outline,
              onPressed: canAdd ? onTakePhoto : null,
            ),
            AppButton(
              label: 'Choose Gallery',
              icon: Icons.photo_library_outlined,
              variant: AppButtonVariant.outline,
              onPressed: canAdd ? onChooseGallery : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${images.length}/$maxFieldReportImages images attached',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        if (uploading) ...[
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Uploading selected images...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorMessage!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (images.isEmpty)
          const AppCard(
            child: Row(
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.muted,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No images selected. Add a photo when it helps staff understand the case.',
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  return _ImageTile(
                    image: images[index],
                    index: index,
                    enabled: enabled && !uploading,
                    canMoveUp: index > 0,
                    canMoveDown: index < images.length - 1,
                    onPreview: () => _showPreview(context, images[index]),
                    onRemove: () => onRemove(index),
                    onReplace: () => onReplace(index),
                    onMoveUp: () => onMoveUp(index),
                    onMoveDown: () => onMoveDown(index),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  void _showPreview(BuildContext context, FieldReportImage image) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(image.fileName, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: 'Close preview',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: _ImagePreview(image: image, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.image,
    required this.index,
    required this.enabled,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onPreview,
    required this.onRemove,
    required this.onReplace,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final FieldReportImage image;
  final int index;
  final bool enabled;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onPreview;
  final VoidCallback onRemove;
  final VoidCallback onReplace;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Selected report image ${index + 1}',
      button: true,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onPreview,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                child: _ImagePreview(image: image),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.isLocal ? 'Ready to upload' : 'Attached',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: image.isLocal
                          ? AppColors.warning
                          : AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    image.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      IconButton(
                        tooltip: 'Replace image',
                        onPressed: enabled ? onReplace : null,
                        icon: const Icon(Icons.swap_horiz),
                      ),
                      IconButton(
                        tooltip: 'Remove image',
                        onPressed: enabled ? onRemove : null,
                        icon: const Icon(Icons.delete_outline),
                      ),
                      IconButton(
                        tooltip: 'Move image earlier',
                        onPressed: enabled && canMoveUp ? onMoveUp : null,
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: 'Move image later',
                        onPressed: enabled && canMoveDown ? onMoveDown : null,
                        icon: const Icon(Icons.arrow_downward),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image, this.fit = BoxFit.cover});

  final FieldReportImage image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = image.bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
      );
    }
    final url = image.url;
    if (url != null) {
      return AppNetworkImage(
        url: url,
        fit: fit,
        semanticLabel: image.fileName,
        fallback: const ColoredBox(
          color: AppColors.softIcon,
          child: Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }
    return const ColoredBox(
      color: AppColors.softIcon,
      child: Center(child: Icon(Icons.image_not_supported_outlined)),
    );
  }
}
