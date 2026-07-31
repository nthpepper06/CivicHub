import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_responsive.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../data/models/login_request.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().submit(
      LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.cityHero),
        child: SafeArea(
          child: BlocBuilder<LoginCubit, LoginState>(
            builder: (context, state) {
              return Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppResponsive(
                    maxWidth: 1040,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 820;
                        final form = _LoginForm(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          passwordFocusNode: _passwordFocusNode,
                          obscurePassword: _obscurePassword,
                          state: state,
                          onSubmit: _submit,
                          onTogglePassword: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        );
                        if (!wide) {
                          return _LoginForm(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            passwordFocusNode: _passwordFocusNode,
                            obscurePassword: _obscurePassword,
                            state: state,
                            compact: true,
                            onSubmit: _submit,
                            onTogglePassword: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(child: _LoginBrandPanel()),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(child: form),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      gradient: AppGradients.cityHero,
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: AppColors.surface.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'CivicHub',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.surface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Civic intelligence for every citizen report.',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sign in to track city service requests, status updates, and public response activity in one trusted workspace.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _UrbanNetworkVisual(),
        ],
      ),
    );
  }
}

class _UrbanNetworkVisual extends StatelessWidget {
  const _UrbanNetworkVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          for (final node in const [
            _NodeSpec(24, 28, 16),
            _NodeSpec(120, 18, 10),
            _NodeSpec(210, 66, 14),
            _NodeSpec(74, 116, 12),
            _NodeSpec(178, 132, 18),
          ])
            Positioned(
              left: node.left,
              top: node.top,
              child: Container(
                width: node.size,
                height: node.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withValues(alpha: 0.5),
                  border: Border.all(color: AppColors.surface),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.surface.withValues(alpha: 0.16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeSpec {
  const _NodeSpec(this.left, this.top, this.size);

  final double left;
  final double top;
  final double size;
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.state,
    required this.onSubmit,
    required this.onTogglePassword,
    this.compact = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final LoginState state;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePassword;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: const Icon(
                    Icons.account_balance_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'CivicHub',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Citizen Login',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!compact)
              Text(
                'Access your reports and city updates securely.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
            AppTextField(
              controller: emailController,
              label: 'E-mail',
              hintText: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !state.isSubmitting,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(passwordFocusNode);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              label: 'Password',
              hintText: 'Your password',
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enabled: !state.isSubmitting,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
              onFieldSubmitted: (_) => onSubmit(),
              suffixIcon: IconButton(
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: state.isSubmitting ? null : onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: state.isSubmitting ? 'Signing In...' : 'Log In',
              onPressed: state.isSubmitting ? null : onSubmit,
            ),
            if (state.status == LoginStatus.failure &&
                state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppError(title: 'Login failed', message: state.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }
}
