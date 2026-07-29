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
import '../../domain/models/report_detail.dart';
import '../../domain/models/report_status.dart';
import '../../domain/repositories/reports_repository.dart';
import '../cubit/edit_report_cubit.dart';
import '../cubit/edit_report_state.dart';

class EditReportScreen extends StatelessWidget {
  const EditReportScreen({required this.report, super.key});

  final CitizenReportDetail report;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditReportCubit(
        reportsRepository: context.read<ReportsRepository>(),
        initialReport: report,
      )..loadCategories(),
      child: _EditReportView(report: report),
    );
  }
}

class _EditReportView extends StatefulWidget {
  const _EditReportView({required this.report});

  final CitizenReportDetail report;

  @override
  State<_EditReportView> createState() => _EditReportViewState();
}

class _EditReportViewState extends State<_EditReportView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final List<TextEditingController> _imageControllers;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    _titleController = TextEditingController(text: report.title);
    _descriptionController = TextEditingController(text: report.description);
    _addressController = TextEditingController(text: report.address);
    _latitudeController = TextEditingController(
      text: report.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: report.longitude?.toString() ?? '',
    );
    _imageControllers = report.images.isEmpty
        ? [TextEditingController()]
        : [
            for (final image in report.images)
              TextEditingController(text: image.url),
          ];
  }

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

  Future<void> _update(EditReportState state) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final categoryId = state.selectedCategoryId;
    if (categoryId == null) {
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
        imageUrls: _imageControllers
            .map((controller) => controller.text.trim())
            .where((url) => url.isNotEmpty)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.report.status != ReportStatus.pending) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: AppEmpty(
              title: 'Report cannot be edited',
              message: 'Only pending reports can be updated.',
              icon: Icons.lock_outline,
            ),
          ),
        ),
      );
    }

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
        body: SafeArea(
          child: BlocBuilder<EditReportCubit, EditReportState>(
            builder: (context, state) {
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
                        state.categoryErrorMessage ?? 'Please try again later.',
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
                      textInputAction: TextInputAction.next,
                      enabled: !_isUpdating(state),
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
                      enabled: !_isUpdating(state),
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
                      enabled: !_isUpdating(state),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Address',
                      controller: _addressController,
                      textInputAction: TextInputAction.next,
                      enabled: !_isUpdating(state),
                      validator: (value) => _requiredMax(
                        value,
                        requiredMessage: 'Address is required',
                        maxLength: 500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Latitude',
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            enabled: !_isUpdating(state),
                            validator: (value) =>
                                _coordinateValidator(value, min: -90, max: 90),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            label: 'Longitude',
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            enabled: !_isUpdating(state),
                            validator: (value) => _coordinateValidator(
                              value,
                              min: -180,
                              max: 180,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ImageUrlFields(
                      controllers: _imageControllers,
                      enabled: !_isUpdating(state),
                      onAdd: _addImageUrlField,
                      onRemove: _removeImageUrlField,
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
                      label: _isUpdating(state)
                          ? 'Updating...'
                          : 'Update Report',
                      icon: Icons.save_outlined,
                      onPressed: state.canSubmit ? () => _update(state) : null,
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

  bool _isUpdating(EditReportState state) {
    return state.submitStatus == EditReportSubmitStatus.updating;
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
