import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/models/status_history_item.dart';

/// Chronological audit timeline showing all status changes for a report.
class StatusTimelineWidget extends StatelessWidget {
  final List<StatusHistoryItem> history;

  const StatusTimelineWidget({super.key, required this.history});

  Color _getNodeColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppColors.statusPending;
      case 'IN_PROGRESS':
        return AppColors.statusInProgress;
      case 'COMPLETED':
        return AppColors.statusCompleted;
      case 'REJECTED':
        return AppColors.statusRejected;
      default:
        return AppColors.primary;
    }
  }

  IconData _getNodeIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.hourglass_top_rounded;
      case 'IN_PROGRESS':
        return Icons.sync_rounded;
      case 'COMPLETED':
        return Icons.check_circle_outline;
      case 'REJECTED':
        return Icons.cancel_outlined;
      default:
        return Icons.radio_button_checked;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No status updates recorded yet.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final isLast = index == history.length - 1;
        final color = _getNodeColor(item.newStatus);
        final icon = _getNodeIcon(item.newStatus);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Timeline Icon & Vertical Line
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Right: Event Details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(status: item.newStatus),
                          if (item.createdAt != null)
                            Text(
                              dateFormat.format(item.createdAt!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Transition narrative
                      Text(
                        item.oldStatus != null &&
                                item.oldStatus!.isNotEmpty &&
                                item.oldStatus != item.newStatus
                            ? 'Status moved from ${item.oldStatus} to ${item.newStatus}'
                            : 'Report initially submitted',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      // Admin Note callout
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.notes_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.notes!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Changer metadata
                      if (item.changedByName != null &&
                          item.changedByName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Recorded by: ${item.changedByName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
