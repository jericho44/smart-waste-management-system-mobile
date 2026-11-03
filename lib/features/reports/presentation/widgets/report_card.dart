import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/models/waste_report.dart';

/// Report card widget matching specification 4.2:
/// Displays image, title, category, status, submission date, and short description.
class ReportCard extends StatelessWidget {
  final WasteReport report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go('/reports/${report.uuid}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.surfaceVariant,
                  child:
                      report.primaryImageUrl != null &&
                          report.primaryImageUrl!.isNotEmpty
                      ? Image.network(
                          report.primaryImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.image_outlined,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                        )
                      : const Icon(
                          Icons.delete_outline,
                          color: AppColors.primary,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Report information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: category and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              report.category?.name ?? 'General',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Short description
                    if (report.description.isNotEmpty) ...[
                      Text(
                        report.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Footer: Address & Date
                    Row(
                      children: [
                        if (report.address != null &&
                            report.address!.isNotEmpty) ...[
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              report.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (report.createdAt != null) ...[
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            dateFormat.format(report.createdAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
