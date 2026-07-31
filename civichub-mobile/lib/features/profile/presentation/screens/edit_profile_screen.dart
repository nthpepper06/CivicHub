import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/data/models/profile_update_request.dart';
import '../../../auth/domain/models/citizen_profile.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/edit_profile_cubit.dart';
import '../cubit/edit_profile_state.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditProfileCubit(
        authRepository: context.read<AuthRepository>(),
        authCubit: context.read<AuthCubit>(),
      ),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _avatarController = TextEditingController(text: user?.avatar ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<EditProfileCubit>();
    if (cubit.state.isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    await cubit.submit(
      ProfileUpdateRequest(
        fullName: _nameController.text,
        phone: _phoneController.text,
        avatar: _avatarController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditProfileCubit, EditProfileState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == EditProfileStatus.success,
      listener: (context, state) => context.pop(true),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leadingWidth: 86,
          leading: TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          title: const Text('Edit Profile'),
          actions: [
            BlocBuilder<EditProfileCubit, EditProfileState>(
              builder: (context, state) {
                return TextButton(
                  onPressed: state.isSubmitting ? null : _submit,
                  child: Text(state.isSubmitting ? 'Saving...' : 'Save'),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final user = authState.user;
              if (user == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return BlocBuilder<EditProfileCubit, EditProfileState>(
                builder: (context, editState) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Center(child: _AvatarPreview(user: user)),
                        const SizedBox(height: AppSpacing.xxl),
                        if (editState.status == EditProfileStatus.failure &&
                            editState.errorMessage != null) ...[
                          AppError(
                            title: 'Profile was not updated',
                            message: editState.errorMessage!,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        AppTextField(
                          label: 'Name',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          enabled: !editState.isSubmitting,
                          validator: _validateName,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _InfoRow(label: 'Email ID', value: user.email),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Mobile number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          enabled: !editState.isSubmitting,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Avatar URL',
                          controller: _avatarController,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          enabled: !editState.isSubmitting,
                          validator: _validateAvatar,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppButton(
                          label: editState.isSubmitting
                              ? 'Saving...'
                              : 'Save Profile',
                          onPressed: editState.isSubmitting ? null : _submit,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.ghost,
                          onPressed: editState.isSubmitting
                              ? null
                              : () => context.pop(false),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Name is required';
    }
    if (normalized.length > 100) {
      return 'Name must be 100 characters or fewer';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.length > 20) {
      return 'Phone must be 20 characters or fewer';
    }
    return null;
  }

  String? _validateAvatar(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.length > 500) {
      return 'Avatar URL must be 500 characters or fewer';
    }
    return null;
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.user});

  final CitizenProfile user;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            width: 90,
            height: 90,
            child: user.hasAvatar
                ? AppNetworkImage(
                    url: user.avatar!,
                    fit: BoxFit.cover,
                    logicalWidth: 90,
                    logicalHeight: 90,
                    fallback: _Fallback(user: user),
                  )
                : _Fallback(user: user),
          ),
        ),
        Positioned(
          bottom: -14,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.link_outlined,
              color: AppColors.muted,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.user});

  final CitizenProfile user;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF65708D)),
      child: Center(
        child: Text(
          user.initials,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
