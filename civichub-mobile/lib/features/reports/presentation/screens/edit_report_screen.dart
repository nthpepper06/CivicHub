import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/civic_page_shell.dart';
import '../../../../core/widgets/location_picker.dart';
import '../../domain/models/create_report_request.dart';
import '../../domain/models/report_category.dart';
import '../../domain/models/report_detail.dart';
import '../../domain/models/report_image_upload_file.dart';
import '../../domain/models/report_status.dart';
import '../../domain/repositories/reports_repository.dart';
import '../cubit/edit_report_cubit.dart';
import '../cubit/edit_report_state.dart';
import '../widgets/field_report_image_picker.dart';

class EditReportScreen extends StatelessWidget {
  const EditReportScreen({
    required this.reportId,
    this.initialReport,
    super.key,
  });

  final int reportId;
  final CitizenReportDetail? initialReport;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditReportCubit(
        reportsRepository: context.read<ReportsRepository>(),
        reportId: reportId,
        initialReport: initialReport,
      )..load(),
      child: const _EditReportView(),
    );
  }
}

class _EditReportView extends StatefulWidget {
  const _EditReportView();

  @override
  State<_EditReportView> createState() => _EditReportViewState();
}

class _EditReportViewState extends State<_EditReportView> {
  static const _maxImageBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  final _images = <FieldReportImage>[];

  bool _controllersInitialized = false;
  bool _uploadingImages = false;
  String? _imageErrorMessage;
  int _imageSequence = 0;

  @override
  void initState() {
    super.initState();
    final report = context.read<EditReportCubit>().state.report;
    if (report != null) {
      _initializeControllers(report);
    }
  }

  @override
  void dispose() {
    if (_controllersInitialized) {
      _titleController.dispose();
      _descriptionController.dispose();
      _addressController.dispose();
      _latitudeController.dispose();
      _longitudeController.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(CitizenReportDetail report) {
    _titleController = TextEditingController(text: report.title);
    _descriptionController = TextEditingController(text: report.description);
    _addressController = TextEditingController(text: report.address);
    _latitudeController = TextEditingController(
      text: report.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: report.longitude?.toString() ?? '',
    );
    _images
      ..clear()
      ..addAll([
        for (final image in report.images)
          FieldReportImage.remote(id: 'remote-${image.id}', url: image.url),
      ]);
    _controllersInitialized = true;
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

  Future<void> _update(EditReportState state) async {
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

    await context.read<EditReportCubit>().update(
      CreateReportRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        categoryId: categoryId,
        latitude: _nullableDouble(_latitudeController.text),
        longitude: _nullableDouble(_longitudeController.text),
        imageUrls: imageUrls,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditReportCubit, EditReportState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == EditReportSubmitStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Report')),
        body: CivicBackground(
          child: SafeArea(
            child: BlocBuilder<EditReportCubit, EditReportState>(
              builder: (context, state) {
                final report = state.report;
                if (state.status == EditReportStatus.loadingReport ||
                    state.status == EditReportStatus.initial &&
                        report == null) {
                  return const Center(
                    child: AppLoading(message: 'Loading report'),
                  );
                }

                if (state.status == EditReportStatus.reportFailure) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppError(
                      title: 'Unable to load report',
                      message: state.reportErrorMessage ?? 'Please try again.',
                      onRetry: context.read<EditReportCubit>().loadReport,
                    ),
                  );
                }

                if (report == null) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: AppEmpty(
                      title: 'Report not found',
                      message: 'This report is unavailable.',
                      icon: Icons.assignment_late_outlined,
                    ),
                  );
                }

                if (report.status != ReportStatus.pending) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: AppEmpty(
                      title: 'Report cannot be edited',
                      message: 'Only pending reports can be updated.',
                      icon: Icons.lock_outline,
                    ),
                  );
                }

                if (!_controllersInitialized) {
                  _initializeControllers(report);
                }

                if (state.status == EditReportStatus.loadingCategories) {
                  return const Center(
                    child: AppLoading(message: 'Loading categories'),
                  );
                }

                if (state.status == EditReportStatus.categoryFailure) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppError(
                      title: 'Unable to load categories',
                      message:
                          state.categoryErrorMessage ??
                          'Please try again later.',
                      onRetry: context.read<EditReportCubit>().loadCategories,
                    ),
                  );
                }

                if (state.categories.isEmpty &&
                    state.status == EditReportStatus.ready) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: AppEmpty(
                      title: 'No categories available',
                      message:
                          'Reports need an active category before they can be updated.',
                      icon: Icons.category_outlined,
                    ),
                  );
                }

                final busy = _isUpdating(state);
                return Form(
                  key: _formKey,
                  child: CivicPageShell(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      const CivicHeroPanel(
                        title: 'Case Update',
                        subtitle:
                            'Adjust evidence, location, and details while this case is still pending.',
                        icon: Icons.edit_location_alt_outlined,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CivicFormSection(
                        title: 'Images',
                        subtitle:
                            'Add, replace, remove, or reorder attached evidence.',
                        icon: Icons.image_outlined,
                        children: [
                          FieldReportImagePicker(
                            images: _images,
                            enabled: !busy,
                            uploading: _uploadingImages,
                            errorMessage: _imageErrorMessage,
                            onTakePhoto: _takePhoto,
                            onChooseGallery: _chooseGallery,
                            onRemove: _removeImage,
                            onReplace: _replaceImage,
                            onMoveUp: (index) => _moveImage(index, index - 1),
                            onMoveDown: (index) => _moveImage(index, index + 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CivicFormSection(
                        title: 'Location',
                        subtitle:
                            'Confirm the address, use current location, or pin the point on the map.',
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
                        subtitle: 'Preserve accurate routing for city teams.',
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
                        subtitle: 'Keep the title and description actionable.',
                        icon: Icons.article_outlined,
                        children: [
                          AppTextField(
                            label: 'Title',
                            controller: _titleController,
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
                        ],
                      ),
                      if (state.submitErrorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppError(
                          title: 'Report was not updated',
                          message: state.submitErrorMessage!,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: busy ? 'Updating...' : 'Update Report',
                        icon: Icons.save_outlined,
                        onPressed: state.canSubmit && !_uploadingImages
                            ? () => _update(state)
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

  bool _isUpdating(EditReportState state) {
    return state.submitStatus == EditReportSubmitStatus.updating ||
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
      decoration: const InputDecoration(labelText: 'Category'),
      items: [
        for (final category in categories)
          DropdownMenuItem<int>(value: category.id, child: Text(category.name)),
      ],
      onChanged: enabled
          ? (value) => context.read<EditReportCubit>().selectCategory(value)
          : null,
      validator: (value) => value == null ? 'Category is required' : null,
    );
  }
}
