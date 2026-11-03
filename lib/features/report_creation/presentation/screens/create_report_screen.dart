import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../state/report_creation_notifier.dart';
import '../state/report_creation_state.dart';
import '../widgets/category_dropdown_field.dart';
import '../widgets/image_picker_section.dart';
import '../widgets/location_picker_card.dart';

/// Screen allowing citizen users to submit a new waste report.
class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();

    // Trigger initial category fetch and GPS acquisition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportCreationNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final newReport = await ref
        .read(reportCreationNotifierProvider.notifier)
        .submitReport(
          title: _titleController.text,
          description: _descriptionController.text,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
        );

    if (!mounted) return;

    if (newReport != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Waste report "${newReport.title}" submitted successfully! Assigned status: PENDING.',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );

      // Navigate to report details screen
      context.go('/reports/${newReport.uuid}');
    } else {
      final currentState = ref.read(reportCreationNotifierProvider);
      if (currentState.fieldErrors.isNotEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Please correct the highlighted form errors before submitting.',
            ),
            backgroundColor: AppColors.statusPending,
          ),
        );
      } else if (currentState.errorMessage != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(currentState.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(reportCreationNotifierProvider);
    final notifier = ref.read(reportCreationNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Waste Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report Waste Incident',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your report will be sent to municipal sanitation teams for review.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              _buildSectionHeader('Report Title', isRequired: true),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                enabled: !formState.isSubmitting,
                maxLength: 255,
                decoration: InputDecoration(
                  hintText: 'e.g. Overflowing dumpster at intersection',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.title,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: formState.errorFor('title') != null
                          ? AppColors.error
                          : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: formState.errorFor('title') != null
                          ? AppColors.error
                          : AppColors.border,
                    ),
                  ),
                  errorText: formState.errorFor('title'),
                ),
              ),
              const SizedBox(height: 14),

              // Waste Category Selector
              CategoryDropdownField(
                categories: formState.categories,
                selectedCategory: formState.selectedCategory,
                onSelected: notifier.selectCategory,
                isLoading:
                    formState.status == ReportCreationStatus.loadingCategories,
                isSubmitting: formState.isSubmitting,
                errorMessage: formState.errorFor('category_uuid'),
              ),
              const SizedBox(height: 18),

              // Description Field
              _buildSectionHeader('Detailed Description', isRequired: true),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                enabled: !formState.isSubmitting,
                maxLines: 4,
                maxLength: 5000,
                decoration: InputDecoration(
                  hintText: 'Describe the type of waste, estimated amount, and any hazards...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: formState.errorFor('description') != null
                          ? AppColors.error
                          : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: formState.errorFor('description') != null
                          ? AppColors.error
                          : AppColors.border,
                    ),
                  ),
                  errorText: formState.errorFor('description'),
                ),
              ),
              const SizedBox(height: 18),

              // Waste Photos Section
              ImagePickerSection(
                images: formState.images,
                onPickCamera: notifier.captureImageFromCamera,
                onPickGallery: notifier.pickImagesFromGallery,
                onRemoveImage: notifier.removeImage,
                errorMessage: formState.errorFor('images'),
                isSubmitting: formState.isSubmitting,
              ),
              const SizedBox(height: 18),

              // GPS Location Card
              LocationPickerCard(
                locationStatus: formState.locationStatus,
                latitude: formState.latitude,
                longitude: formState.longitude,
                accuracy: formState.locationAccuracy,
                locationErrorMessage: formState.locationErrorMessage,
                onRetry: notifier.fetchLocation,
                onOpenAppSettings: notifier.openAppSettings,
                onOpenLocationSettings: notifier.openLocationSettings,
                addressController: _addressController,
                fieldError:
                    formState.errorFor('location') ??
                    formState.errorFor('latitude') ??
                    formState.errorFor('longitude'),
                isSubmitting: formState.isSubmitting,
              ),
              const SizedBox(height: 24),

              // In-Flight Upload Progress Bar
              if (formState.isSubmitting) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Submitting report & uploading images...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(formState.uploadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: formState.uploadProgress,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.5,
                  ),
                ),
                onPressed: formState.canSubmit ? _handleSubmit : null,
                child: formState.isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Submitting Report...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Submit Report',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
      ],
    );
  }
}
