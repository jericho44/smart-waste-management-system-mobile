import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/report_repository.dart';
import '../state/reports_list_notifier.dart';
import '../widgets/report_card.dart';

/// Screen displaying paginated list of user's waste reports with search and filter capabilities.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsListNotifierProvider.notifier).loadReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(reportsListNotifierProvider.notifier).loadNextPage();
    }
  }

  Future<void> _onRefresh() async {
    await ref
        .read(reportsListNotifierProvider.notifier)
        .loadReports(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(reportsListNotifierProvider);
    final categoriesAsync = ref.watch(wasteCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Waste Reports'),
        actions: [
          IconButton(
            tooltip: 'Create Report',
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/reports/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) {
                    ref
                        .read(reportsListNotifierProvider.notifier)
                        .setSearch(query);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by title, location or description...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(reportsListNotifierProvider.notifier)
                                  .setSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        isSelected: listState.selectedStatus == null,
                        onSelected: () => ref
                            .read(reportsListNotifierProvider.notifier)
                            .setStatusFilter(null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Pending',
                        color: AppColors.statusPending,
                        isSelected:
                            listState.selectedStatus ==
                            AppConstants.statusPending,
                        onSelected: () => ref
                            .read(reportsListNotifierProvider.notifier)
                            .setStatusFilter(AppConstants.statusPending),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'In Progress',
                        color: AppColors.statusInProgress,
                        isSelected:
                            listState.selectedStatus ==
                            AppConstants.statusInProgress,
                        onSelected: () => ref
                            .read(reportsListNotifierProvider.notifier)
                            .setStatusFilter(AppConstants.statusInProgress),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Completed',
                        color: AppColors.statusCompleted,
                        isSelected:
                            listState.selectedStatus ==
                            AppConstants.statusCompleted,
                        onSelected: () => ref
                            .read(reportsListNotifierProvider.notifier)
                            .setStatusFilter(AppConstants.statusCompleted),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Rejected',
                        color: AppColors.statusRejected,
                        isSelected:
                            listState.selectedStatus ==
                            AppConstants.statusRejected,
                        onSelected: () => ref
                            .read(reportsListNotifierProvider.notifier)
                            .setStatusFilter(AppConstants.statusRejected),
                      ),
                    ],
                  ),
                ),

                // Category Filter (if categories loaded)
                categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: listState.selectedCategoryUuid,
                                isDense: true,
                                hint: const Text(
                                  'Filter by Category (All)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      'All Categories',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  ...categories.map(
                                    (cat) => DropdownMenuItem<String?>(
                                      value: cat.uuid,
                                      child: Text(
                                        cat.name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  ref
                                      .read(
                                        reportsListNotifierProvider.notifier,
                                      )
                                      .setCategoryFilter(value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Report List Body
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: _buildListContent(listState),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/reports/create'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('New Report'),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : (color ?? AppColors.textSecondary),
      ),
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: color ?? AppColors.primary,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildListContent(dynamic listState) {
    if (listState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (listState.errorMessage != null && listState.reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.statusRejected,
              ),
              const SizedBox(height: 12),
              Text(
                listState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(reportsListNotifierProvider.notifier).loadReports();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (listState.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                listState.hasActiveFilters
                    ? 'No Reports Found'
                    : 'No Reports Submitted Yet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                listState.hasActiveFilters
                    ? 'Try clearing your search query or status filter.'
                    : 'Help keep your community clean by reporting waste issues.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (listState.hasActiveFilters)
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(reportsListNotifierProvider.notifier)
                        .setSearch('');
                    ref
                        .read(reportsListNotifierProvider.notifier)
                        .setStatusFilter(null);
                    ref
                        .read(reportsListNotifierProvider.notifier)
                        .setCategoryFilter(null);
                  },
                  child: const Text('Clear Filters'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => context.go('/reports/create'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Report'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: listState.reports.length + (listState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == listState.reports.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final report = listState.reports[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ReportCard(report: report),
        );
      },
    );
  }
}
