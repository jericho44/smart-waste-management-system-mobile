import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../state/report_creation_state.dart';

/// Interactive card explaining, obtaining, and confirming device GPS location.
class LocationPickerCard extends StatelessWidget {
  final LocationStatus locationStatus;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? locationErrorMessage;
  final VoidCallback onRetry;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;
  final TextEditingController addressController;
  final String? fieldError;
  final bool isSubmitting;

  const LocationPickerCard({
    super.key,
    required this.locationStatus,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.locationErrorMessage,
    required this.onRetry,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
    required this.addressController,
    this.fieldError,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: fieldError != null ? AppColors.error : AppColors.border,
          width: fieldError != null ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'GPS Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),

            // Rationale explanation
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Precise GPS coordinates are required so sanitation teams can locate the site.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Location Content Body
            _buildLocationBody(context, hasCoords),

            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),

            // Address Input
            const Text(
              'Specific Address / Landmark (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: addressController,
              enabled: !isSubmitting,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. In front of Blok M Square gate, behind the bus stop...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),

            if (fieldError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fieldError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    switch (locationStatus) {
      case LocationStatus.acquiring:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.statusPending.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.statusPending,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Acquiring...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusPending,
                ),
              ),
            ],
          ),
        );
      case LocationStatus.acquired:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.statusCompleted.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 13,
                color: AppColors.statusCompleted,
              ),
              SizedBox(width: 4),
              Text(
                'Coordinates Acquired',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusCompleted,
                ),
              ),
            ],
          ),
        );
      case LocationStatus.serviceDisabled:
      case LocationStatus.permissionDenied:
      case LocationStatus.permissionDeniedForever:
      case LocationStatus.error:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber, size: 13, color: AppColors.error),
              SizedBox(width: 4),
              Text(
                'Action Required',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        );
      case LocationStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLocationBody(BuildContext context, bool hasCoords) {
    if (hasCoords) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.my_location,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latitude: ${latitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Longitude: ${longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (accuracy != null)
                        Text(
                          'Estimated Accuracy: ±${accuracy!.toStringAsFixed(1)}m',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: isSubmitting ? null : onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Update'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Handlers for error states
    switch (locationStatus) {
      case LocationStatus.serviceDisabled:
        return _buildErrorAction(
          icon: Icons.location_disabled,
          message:
              locationErrorMessage ?? 'GPS is disabled on your mobile device.',
          buttonLabel: 'Open Location Settings',
          onPressed: onOpenLocationSettings,
        );
      case LocationStatus.permissionDenied:
        return _buildErrorAction(
          icon: Icons.security_outlined,
          message:
              locationErrorMessage ??
              'Location permission is required to detect waste coordinates.',
          buttonLabel: 'Grant Permission',
          onPressed: onRetry,
        );
      case LocationStatus.permissionDeniedForever:
        return _buildErrorAction(
          icon: Icons.app_settings_alt_outlined,
          message: locationErrorMessage ?? 'Location permissions are permanently denied. Please grant permission in App Settings.',
          buttonLabel: 'Open App Settings',
          onPressed: onOpenAppSettings,
        );
      case LocationStatus.error:
        return _buildErrorAction(
          icon: Icons.signal_cellular_connected_no_internet_0_bar,
          message: locationErrorMessage ?? 'Unable to get GPS coordinates. Please ensure you have a clear sky view and tap Retry.',
          buttonLabel: 'Retry GPS Retrieval',
          onPressed: onRetry,
        );
      case LocationStatus.acquiring:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Contacting GPS satellites for current coordinates...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      case LocationStatus.idle:
      case LocationStatus.acquired:
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorAction({
    required IconData icon,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: isSubmitting ? null : onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
