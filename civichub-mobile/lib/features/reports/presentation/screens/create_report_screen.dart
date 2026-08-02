import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/civic_page_shell.dart';
import '../../../../core/widgets/location_picker.dart';
import '../../../ai/domain/repositories/ai_assist_repository.dart';
import '../../../ai/presentation/cubit/ai_suggestion_cubit.dart';
import '../../../ai/presentation/cubit/ai_suggestion_state.dart';
import '../../../ai/presentation/widgets/ai_suggestion_preview_dialog.dart';
import '../../domain/models/create_report_request.dart';
import '../../domain/models/report_category.dart';
import '../../domain/models/report_image_upload_file.dart';
import '../../domain/repositories/reports_repository.dart';
import '../cubit/create_report_cubit.dart';
import '../cubit/create_report_state.dart';
import '../widgets/field_report_image_picker.dart';

class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CreateReportCubit(
            reportsRepository: context.read<ReportsRepository>(),
          )..loadCategories(),
        ),
        BlocProvider(
          create: (context) => AiSuggestionCubit(
            aiAssistRepository: context.read<AiAssistRepository>(),
          ),
        ),
      ],
      child: const _CreateReportView(),
    );
  }
}

class _CreateReportView extends StatefulWidget {
  const _CreateReportView();

  @override
  State<_CreateReportView> createState() => _CreateReportViewState();
}

class _CreateReportViewState extends State<_CreateReportView> {
  static const _maxImageBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _images = <FieldReportImage>[];

  bool _uploadingImages = false;
  String? _imageErrorMessage;
  String? _describingImageId;
  int _imageSequence = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    await _pickSingleImage(ImageSource.camera);
  }

  Future<void> _chooseGallery() async {
    final remaining = maxFieldReportImages - _images.length;
    if (remaining <= 0) {
      _setImageError('You can attach up to $maxFieldReportImages images.');
      return;
    }
    try {
      final files = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        limit: remaining,
        requestFullMetadata: false,
      );
      await _addPickedFiles(files.take(remaining));
    } on PlatformException catch (error) {
      _setImageError(_permissionMessage(error));
    }
  }

  Future<void> _replaceImage(int index) async {
    if (index < 0 || index >= _images.length) {
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Retake with camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Replace from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) {
      return;
    }
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (file == null) {
        return;
      }
      final image = await _toFieldImage(file);
      setState(() {
        _images[index] = image;
        _imageErrorMessage = null;
      });
    } on PlatformException catch (error) {
      _setImageError(_permissionMessage(error));
    } on FormatException catch (error) {
      _setImageError(error.message);
    }
  }

  Future<void> _pickSingleImage(ImageSource source) async {
    if (_images.length >= maxFieldReportImages) {
      _setImageError('You can attach up to $maxFieldReportImages images.');
      return;
    }
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (file == null) {
        return;
      }
      await _addPickedFiles([file]);
    } on PlatformException catch (error) {
      _setImageError(_permissionMessage(error));
    }
  }

  Future<void> _addPickedFiles(Iterable<XFile> files) async {
    final nextImages = <FieldReportImage>[];
    for (final file in files) {
      nextImages.add(await _toFieldImage(file));
    }
    if (nextImages.isEmpty) {
      return;
    }
    setState(() {
      _images.addAll(nextImages);
      _imageErrorMessage = null;
    });
  }

  Future<FieldReportImage> _toFieldImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > _maxImageBytes) {
      throw const FormatException('Image file must be 5 MB or smaller.');
    }
    final contentType = file.mimeType ?? _contentTypeFromName(file.name);
    if (!_isSupportedContentType(contentType)) {
      throw const FormatException(
        'Only JPEG, PNG, or WebP images are supported.',
      );
    }
    return FieldReportImage.local(
      id: 'local-${_imageSequence++}',
      fileName: file.name.isEmpty ? 'report-image.jpg' : file.name,
      contentType: contentType,
      bytes: bytes,
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageErrorMessage = null;
    });
  }

  void _moveImage(int from, int to) {
    if (to < 0 || to >= _images.length) {
      return;
    }
    setState(() {
      final image = _images.removeAt(from);
      _images.insert(to, image);
    });
  }

  Future<List<String>?> _uploadImages() async {
    if (_images.isEmpty) {
      return const [];
    }
    setState(() {
      _uploadingImages = true;
      _imageErrorMessage = null;
    });
    final repository = context.read<ReportsRepository>();
    final urls = <String>[];
    try {
      for (final image in _images) {
        final remoteUrl = image.url;
        if (remoteUrl != null) {
          urls.add(remoteUrl);
          continue;
        }
        final bytes = image.bytes;
        if (bytes == null) {
          continue;
        }
        final uploaded = await repository.uploadReportImage(
          ReportImageUploadFile(
            fileName: image.fileName,
            contentType: image.contentType,
            bytes: bytes,
          ),
        );
        urls.add(uploaded.url);
      }
      return urls;
    } on ApiException catch (error) {
      _setImageError(error.message);
      return null;
    } catch (_) {
      _setImageError('Image upload failed. Please try again.');
      return null;
    } finally {
      if (mounted) {
        setState(() => _uploadingImages = false);
      }
    }
  }

  Future<String?> _ensureImageUrl(FieldReportImage image) async {
    final remoteUrl = image.url;
    if (remoteUrl != null) {
      return remoteUrl;
    }
    final bytes = image.bytes;
    if (bytes == null) {
      return null;
    }
    setState(() {
      _describingImageId = image.id;
      _imageErrorMessage = null;
    });
    try {
      final uploaded = await context
          .read<ReportsRepository>()
          .uploadReportImage(
            ReportImageUploadFile(
              fileName: image.fileName,
              contentType: image.contentType,
              bytes: bytes,
            ),
          );
      final index = _images.indexWhere((candidate) => candidate.id == image.id);
      if (index != -1 && mounted) {
        setState(() {
          _images[index] = FieldReportImage.remote(
            id: image.id,
            url: uploaded.url,
          );
        });
      }
      return uploaded.url;
    } on ApiException catch (error) {
      _setImageError(error.message);
      return null;
    } catch (_) {
      _setImageError('Image upload failed. Please try again.');
      return null;
    }
  }

  Future<void> _describeImage(int index) async {
    if (index < 0 || index >= _images.length) {
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppFeedback.show(
        context,
        message: 'Add a title before asking AI to describe the image.',
        type: AppFeedbackType.info,
      );
      return;
    }
    final image = _images[index];
    final imageUrl = await _ensureImageUrl(image);
    if (imageUrl == null || !mounted) {
      setState(() => _describingImageId = null);
      return;
    }
    final cubit = context.read<AiSuggestionCubit>();
    await cubit.describeImage(
      title: title,
      imageUrl: imageUrl,
      location: _addressController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _describingImageId = null);
    final state = cubit.state;
    if (state.status == AiSuggestionStatus.success &&
        state.imageSuggestion != null) {
      await showAiImageContextDialog(
        context: context,
        suggestion: state.imageSuggestion!.suggestion,
        confidence: state.imageSuggestion!.confidence,
      );
      cubit.reset();
      return;
    }
    AppFeedback.show(
      context,
      message: state.errorMessage ?? 'AI image context is unavailable.',
      type: AppFeedbackType.warning,
    );
  }

  Future<void> _improveDescription() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      AppFeedback.show(
        context,
        message: 'Add a title and description before requesting a suggestion.',
        type: AppFeedbackType.info,
      );
      return;
    }
    final cubit = context.read<AiSuggestionCubit>();
    await cubit.improveReportDescription(
      title: title,
      description: description,
    );
    if (!mounted) {
      return;
    }
    final state = cubit.state;
    if (state.status == AiSuggestionStatus.success &&
        state.textSuggestion != null) {
      final accepted = await showAiSuggestionPreviewDialog(
        context: context,
        title: 'Improve description?',
        suggestion: state.textSuggestion!.suggestion,
        metadata: 'AI suggestions are optional. Review before accepting.',
      );
      if (accepted && mounted) {
        _descriptionController.text = state.textSuggestion!.suggestion;
      }
      cubit.reset();
      return;
    }
    AppFeedback.show(
      context,
      message: state.errorMessage ?? 'AI suggestion is unavailable.',
      type: AppFeedbackType.warning,
    );
  }

  Future<void> _submit(CreateReportState state) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final categoryId = state.selectedCategoryId;
    if (categoryId == null) {
      return;
    }

    final imageUrls = await _uploadImages();
    if (imageUrls == null || !mounted) {
      return;
    }

    final request = CreateReportRequest(
      title: _titleController.text,
      description: _descriptionController.text,
      address: _addressController.text,
      categoryId: categoryId,
      latitude: _nullableDouble(_latitudeController.text),
      longitude: _nullableDouble(_longitudeController.text),
      imageUrls: imageUrls,
    );
    await context.read<CreateReportCubit>().submit(request);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateReportCubit, CreateReportState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CreateReportSubmitStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Report')),
        body: CivicBackground(
          child: SafeArea(
            child: BlocBuilder<CreateReportCubit, CreateReportState>(
              builder: (context, state) {
                if (state.status == CreateReportStatus.loadingCategories) {
                  return const Center(
                    child: AppLoading(message: 'Loading categories'),
                  );
                }

                if (state.status == CreateReportStatus.categoryFailure) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppError(
                      title: 'Unable to load categories',
                      message:
                          state.categoryErrorMessage ??
                          'Please try again later.',
                      onRetry: context.read<CreateReportCubit>().loadCategories,
                    ),
                  );
                }

                if (state.categories.isEmpty &&
                    state.status == CreateReportStatus.ready) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: AppEmpty(
                      title: 'No categories available',
                      message:
                          'Reports need an active category before they can be submitted.',
                      icon: Icons.category_outlined,
                    ),
                  );
                }

                final busy = _isSubmitting(state);
                return Form(
                  key: _formKey,
                  child: CivicPageShell(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      const CivicHeroPanel(
                        title: 'Field Report',
                        subtitle:
                            'Capture evidence, confirm the location, and send the case to the city response workflow.',
                        icon: Icons.add_a_photo_outlined,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CivicFormSection(
                        title: 'Images',
                        subtitle:
                            'Take a photo or choose from your gallery before submitting.',
                        icon: Icons.image_outlined,
                        children: [
                          FieldReportImagePicker(
                            images: _images,
                            enabled: !busy,
                            uploading: _uploadingImages,
                            errorMessage: _imageErrorMessage,
                            describingImageId: _describingImageId,
                            onTakePhoto: _takePhoto,
                            onChooseGallery: _chooseGallery,
                            onRemove: _removeImage,
                            onReplace: _replaceImage,
                            onMoveUp: (index) => _moveImage(index, index - 1),
                            onMoveDown: (index) => _moveImage(index, index + 1),
                            onDescribe: _describeImage,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CivicFormSection(
                        title: 'Location',
                        subtitle:
                            'Use current GPS, handle permission prompts, or adjust the pin manually.',
                        icon: Icons.map_outlined,
                        children: [
                          LocationPicker(
                            addressController: _addressController,
                            latitudeController: _latitudeController,
                            longitudeController: _longitudeController,
                            enabled: !busy,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CivicFormSection(
                        title: 'Category',
                        subtitle: 'Route the case to the correct city team.',
                        icon: Icons.category_outlined,
                        children: [
                          _CategoryPicker(
                            categories: state.categories,
                            selectedCategoryId: state.selectedCategoryId,
                            enabled: !busy,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CivicFormSection(
                        title: 'Description',
                        subtitle: 'Keep the report clear and actionable.',
                        icon: Icons.article_outlined,
                        children: [
                          AppTextField(
                            label: 'Title',
                            controller: _titleController,
                            hintText: 'Briefly describe the issue',
                            textInputAction: TextInputAction.next,
                            enabled: !busy,
                            validator: (value) => _requiredMax(
                              value,
                              requiredMessage: 'Title is required',
                              maxLength: 200,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: 'Description',
                            controller: _descriptionController,
                            hintText: 'Add details that help staff respond',
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            minLines: 4,
                            maxLines: 6,
                            enabled: !busy,
                            validator: (value) => _requiredMax(
                              value,
                              requiredMessage: 'Description is required',
                              maxLength: 5000,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          BlocBuilder<AiSuggestionCubit, AiSuggestionState>(
                            builder: (context, aiState) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: AppButton(
                                  label: aiState.isLoading
                                      ? 'Improving...'
                                      : 'Improve Description',
                                  icon: Icons.auto_awesome_outlined,
                                  variant: AppButtonVariant.outline,
                                  onPressed: !busy && !aiState.isLoading
                                      ? _improveDescription
                                      : null,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (state.submitErrorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppError(
                          title: 'Report was not submitted',
                          message: state.submitErrorMessage!,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: busy ? 'Submitting...' : 'Submit Report',
                        icon: Icons.send_outlined,
                        onPressed: state.canSubmit && !_uploadingImages
                            ? () => _submit(state)
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool _isSubmitting(CreateReportState state) {
    return state.submitStatus == CreateReportSubmitStatus.submitting ||
        _uploadingImages;
  }

  String? _requiredMax(
    String? value, {
    required String requiredMessage,
    required int maxLength,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return requiredMessage;
    }
    if (normalized.length > maxLength) {
      return 'Must be $maxLength characters or fewer';
    }
    return null;
  }

  double? _nullableDouble(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  String _contentTypeFromName(String name) {
    final normalized = name.toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  bool _isSupportedContentType(String contentType) {
    return const {
      'image/jpeg',
      'image/png',
      'image/webp',
    }.contains(contentType);
  }

  String _permissionMessage(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('camera')) {
      return 'Camera is unavailable or permission was denied.';
    }
    if (code.contains('photo') || code.contains('gallery')) {
      return 'Photo library permission was denied.';
    }
    return 'Unable to select an image. Please try again.';
  }

  void _setImageError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _imageErrorMessage = message);
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selectedCategoryId,
    required this.enabled,
  });

  final List<ReportCategory> categories;
  final int? selectedCategoryId;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Category',
        hintText: 'Choose a category',
      ),
      items: [
        for (final category in categories)
          DropdownMenuItem<int>(value: category.id, child: Text(category.name)),
      ],
      onChanged: enabled
          ? (value) => context.read<CreateReportCubit>().selectCategory(value)
          : null,
      validator: (value) => value == null ? 'Category is required' : null,
    );
  }
}
