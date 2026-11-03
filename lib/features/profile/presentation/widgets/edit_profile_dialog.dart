import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../authentication/domain/models/authenticated_user.dart';
import '../../domain/models/update_profile_request.dart';
import '../state/profile_notifier.dart';

/// Modal dialog for editing citizen full name and email.
class EditProfileDialog extends ConsumerStatefulWidget {
  final AuthenticatedUser currentUser;

  const EditProfileDialog({super.key, required this.currentUser});

  static Future<void> show(BuildContext context, AuthenticatedUser user) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditProfileDialog(currentUser: user),
    );
  }

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _emailController = TextEditingController(text: widget.currentUser.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await ref
        .read(profileNotifierProvider.notifier)
        .updateProfile(
          UpdateProfileRequest(
            name: _nameController.text,
            email: _emailController.text,
          ),
        );

    if (!mounted) return;

    if (success) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final isSaving = profileState.isUpdatingProfile;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_outline, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Edit Profile'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update your account display name and email address.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Name Field
            const Text(
              'Full Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              enabled: !isSaving,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: profileState.profileErrorFor('name') != null
                        ? AppColors.error
                        : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: profileState.profileErrorFor('name') != null
                        ? AppColors.error
                        : AppColors.border,
                  ),
                ),
                errorText: profileState.profileErrorFor('name'),
              ),
            ),
            const SizedBox(height: 14),

            // Email Field
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              enabled: !isSaving,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: profileState.profileErrorFor('email') != null
                        ? AppColors.error
                        : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: profileState.profileErrorFor('email') != null
                        ? AppColors.error
                        : AppColors.border,
                  ),
                ),
                errorText: profileState.profileErrorFor('email'),
              ),
            ),

            if (profileState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        profileState.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(90, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isSaving ? null : _handleSave,
          child: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
