import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../state/report_details_notifier.dart';
import '../widgets/report_image_gallery.dart';
import '../widgets/report_map_preview.dart';
import '../widgets/status_timeline_widget.dart';

/// Full details screen for a waste report including map, gallery, and status audit timeline.
class ReportDetailsScreen extends ConsumerStatefulWidget {
  final String uuid;

  const ReportDetailsScreen({super.key, required this.uuid});

  @override
  ConsumerState<ReportDetailsScreen> createState() =>
      _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(reportDetailsNotifierProvider(widget.uuid).notifier)
          .loadDetails();
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text(
          'Are you sure you want to delete this pending waste report? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(90, 40),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final success = await ref
        .read(reportDetailsNotifierProvider(widget.uuid).notifier)
        .deleteReport();

    if (!mounted) return;
    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Report deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      router.go('/reports');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsState = ref.watch(reportDetailsNotifierProvider(widget.uuid));

    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/reports'),
        ),
        actions: [
          // Delete action: Only visible & active when status is PENDING per WasteReportPolicy
          if (detailsState.report?.canBeEditedOrDeleted == true)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Delete Pending Report',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (detailsState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (detailsState.errorMessage != null &&
              detailsState.report == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: AppColors.statusRejected,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detailsState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(
                              reportDetailsNotifierProvider(widget.uuid)
                                  .notifier,
                            )
                            .loadDetails();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final report = detailsState.report;
          if (report == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(reportDetailsNotifierProvider(widget.uuid).notifier)
                  .loadDetails();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Card: Title, Status, Category
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  report.category?.name ?? 'General Waste',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              StatusBadge(status: report.status, fontSize: 12),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            report.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (report.createdAt != null) ...[
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Submitted: ${dateFormat.format(report.createdAt!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (report.updatedAt != null &&
                              report.updatedAt != report.createdAt) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.update_outlined,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Updated: ${dateFormat.format(report.updatedAt!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Attached Images Section
                  const Text(
                    'Waste Photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ReportImageGallery(images: report.images),
                  const SizedBox(height: 20),

                  // 3. Description Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            report.description.isNotEmpty
                                ? report.description
                                : 'No detailed description provided.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Location & Map Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Location Details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (report.address != null &&
                              report.address!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              report.address!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ReportMapPreview(
                            latitude: report.latitude,
                            longitude: report.longitude,
                            address: report.address,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Status Audit Timeline Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.timeline_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Resolution History & Timeline',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StatusTimelineWidget(
                            history: detailsState.history.isNotEmpty
                                ? detailsState.history
                                : report.statusHistories,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Backend Policy Information Card
                  if (!report.canBeEditedOrDeleted)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This report is currently under review or resolved and is locked against modifications.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
