import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/create_report_request.dart';
import '../../domain/models/report_category.dart';
import '../../domain/repositories/reports_repository.dart';
import '../cubit/create_report_cubit.dart';
import '../cubit/create_report_state.dart';

class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateReportCubit(
        reportsRepository: context.read<ReportsRepository>(),
      )..loadCategories(),
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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _imageControllers = <TextEditingController>[TextEditingController()];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    for (final controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addImageUrlField() {
    if (_imageControllers.length >= 5) {
      return;
    }
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageUrlField(int index) {
    if (_imageControllers.length == 1) {
      _imageControllers.single.clear();
      return;
    }
    setState(() {
      _imageControllers.removeAt(index).dispose();
    });
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

    final request = CreateReportRequest(
      title: _titleController.text,
      description: _descriptionController.text,
      address: _addressController.text,
      categoryId: categoryId,
      latitude: _nullableDouble(_latitudeController.text),
      longitude: _nullableDouble(_longitudeController.text),
      imageUrls: _imageControllers
          .map((controller) => controller.text.trim())
          .where((url) => url.isNotEmpty)
          .toList(),
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
        body: SafeArea(
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
                        state.categoryErrorMessage ?? 'Please try again later.',
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

              return Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    AppTextField(
                      label: 'Title',
                      controller: _titleController,
                      hintText: 'Briefly describe the issue',
                      textInputAction: TextInputAction.next,
                      enabled: !_isSubmitting(state),
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
                      enabled: !_isSubmitting(state),
                      validator: (value) => _requiredMax(
                        value,
                        requiredMessage: 'Description is required',
                        maxLength: 5000,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CategoryPicker(
                      categories: state.categories,
                      selectedCategoryId: state.selectedCategoryId,
                      enabled: !_isSubmitting(state),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Address',
                      controller: _addressController,
                      hintText: 'Street address or nearby landmark',
                      textInputAction: TextInputAction.next,
                      enabled: !_isSubmitting(state),
                      validator: (value) => _requiredMax(
                        value,
                        requiredMessage: 'Address is required',
                        maxLength: 500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _LocationFields(
                      latitudeController: _latitudeController,
                      longitudeController: _longitudeController,
                      enabled: !_isSubmitting(state),
                      locationLoading: state.locationLoading,
                      locationErrorMessage: state.locationErrorMessage,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ImageUrlFields(
                      controllers: _imageControllers,
                      enabled: !_isSubmitting(state),
                      onAdd: _addImageUrlField,
                      onRemove: _removeImageUrlField,
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
                      label: _isSubmitting(state)
                          ? 'Submitting...'
                          : 'Submit Report',
                      icon: Icons.send_outlined,
                      onPressed: state.canSubmit ? () => _submit(state) : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isSubmitting(CreateReportState state) {
    return state.submitStatus == CreateReportSubmitStatus.submitting;
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

class _LocationFields extends StatelessWidget {
  const _LocationFields({
    required this.latitudeController,
    required this.longitudeController,
    required this.enabled,
    required this.locationLoading,
    required this.locationErrorMessage,
  });

  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final bool enabled;
  final bool locationLoading;
  final String? locationErrorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Latitude',
                controller: latitudeController,
                hintText: 'Optional',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                enabled: enabled,
                validator: (value) =>
                    _coordinateValidator(value, min: -90, max: 90),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Longitude',
                controller: longitudeController,
                hintText: 'Optional',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                enabled: enabled,
                validator: (value) =>
                    _coordinateValidator(value, min: -180, max: 180),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: locationLoading ? 'Getting Location...' : 'Use Current GPS',
          icon: Icons.my_location_outlined,
          variant: AppButtonVariant.outline,
          onPressed: enabled
              ? context.read<CreateReportCubit>().useCurrentLocation
              : null,
        ),
        if (locationErrorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            locationErrorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  String? _coordinateValidator(
    String? value, {
    required double min,
    required double max,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < min || parsed > max) {
      return 'Must be between $min and $max';
    }
    return null;
  }
}

class _ImageUrlFields extends StatelessWidget {
  const _ImageUrlFields({
    required this.controllers,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<TextEditingController> controllers;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image URLs',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < controllers.length; index++) ...[
          TextFormField(
            controller: controllers[index],
            enabled: enabled,
            keyboardType: TextInputType.url,
            textInputAction: index == controllers.length - 1
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Optional image URL',
              prefixIcon: const Icon(Icons.link),
              suffixIcon: IconButton(
                tooltip: 'Remove image URL',
                onPressed: enabled ? () => onRemove(index) : null,
                icon: const Icon(Icons.close),
              ),
            ),
            validator: (value) {
              final normalized = value?.trim() ?? '';
              if (normalized.isEmpty) {
                return null;
              }
              if (normalized.length > 2000) {
                return 'Must be 2000 characters or fewer';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppButton(
          label: 'Add Image URL',
          icon: Icons.add_photo_alternate_outlined,
          variant: AppButtonVariant.outline,
          onPressed: enabled && controllers.length < 5 ? onAdd : null,
        ),
      ],
    );
  }
}
