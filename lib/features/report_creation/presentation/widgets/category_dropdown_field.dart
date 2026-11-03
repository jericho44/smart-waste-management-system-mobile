import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../reports/domain/models/waste_category.dart';

/// Dropdown selector for waste report categorization.
class CategoryDropdownField extends StatelessWidget {
  final List<WasteCategory> categories;
  final WasteCategory? selectedCategory;
  final ValueChanged<WasteCategory?> onSelected;
  final String? errorMessage;
  final bool isLoading;
  final bool isSubmitting;

  const CategoryDropdownField({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    this.errorMessage,
    this.isLoading = false,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waste Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<WasteCategory>(
          initialValue: selectedCategory,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: isLoading
                ? 'Loading categories...'
                : 'Select waste category',
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.category_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorMessage != null
                    ? AppColors.error
                    : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorMessage != null
                    ? AppColors.error
                    : AppColors.border,
              ),
            ),
            errorText: errorMessage,
          ),
          items: categories.map((cat) {
            return DropdownMenuItem<WasteCategory>(
              value: cat,
              child: Text(
                cat.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (isSubmitting || isLoading) ? null : onSelected,
        ),
      ],
    );
  }
}
