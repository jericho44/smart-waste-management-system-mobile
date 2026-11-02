import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Reusable status badge with color coding matching system rules:
/// - Pending: Amber / Yellow
/// - In Progress: Blue
/// - Completed: Green
/// - Rejected: Red
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  Color get _backgroundColor {
    switch (status.toUpperCase()) {
      case AppConstants.statusPending:
        return AppColors.statusPendingBg;
      case AppConstants.statusInProgress:
        return AppColors.statusInProgressBg;
      case AppConstants.statusCompleted:
        return AppColors.statusCompletedBg;
      case AppConstants.statusRejected:
        return AppColors.statusRejectedBg;
      default:
        return AppColors.surfaceVariant;
    }
  }

  Color get _textColor {
    switch (status.toUpperCase()) {
      case AppConstants.statusPending:
        return AppColors.statusPending;
      case AppConstants.statusInProgress:
        return AppColors.statusInProgress;
      case AppConstants.statusCompleted:
        return AppColors.statusCompleted;
      case AppConstants.statusRejected:
        return AppColors.statusRejected;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _displayLabel {
    switch (status.toUpperCase()) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusInProgress:
        return 'In Progress';
      case AppConstants.statusCompleted:
        return 'Completed';
      case AppConstants.statusRejected:
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _displayLabel,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: _textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
