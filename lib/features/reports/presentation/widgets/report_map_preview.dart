import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_colors.dart';

/// Interactive Leaflet/OpenStreetMap preview widget for waste report location.
class ReportMapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;

  const ReportMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartwaste.mobile',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.error,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Coordinates info badge overlay
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    size: 14,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
