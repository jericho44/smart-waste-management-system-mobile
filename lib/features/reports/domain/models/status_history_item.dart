import '../../../../core/constants/app_constants.dart';

/// Single event node in the report status change audit trail.
class StatusHistoryItem {
  final String uuid;
  final String? oldStatus;
  final String newStatus;
  final String? notes;
  final String? changedByName;
  final String? changedByEmail;
  final DateTime? createdAt;

  const StatusHistoryItem({
    required this.uuid,
    this.oldStatus,
    required this.newStatus,
    this.notes,
    this.changedByName,
    this.changedByEmail,
    this.createdAt,
  });

  bool get isInitialSubmission =>
      oldStatus == null || oldStatus!.isEmpty || oldStatus == newStatus;

  bool get isPending => newStatus == AppConstants.statusPending;
  bool get isInProgress => newStatus == AppConstants.statusInProgress;
  bool get isCompleted => newStatus == AppConstants.statusCompleted;
  bool get isRejected => newStatus == AppConstants.statusRejected;

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    String? changerName;
    String? changerEmail;

    if (json['changed_by'] is Map<String, dynamic>) {
      final changer = json['changed_by'] as Map<String, dynamic>;
      changerName = changer['name'] as String?;
      changerEmail = changer['email'] as String?;
    }

    return StatusHistoryItem(
      uuid: json['uuid'] as String? ?? '',
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String? ?? AppConstants.statusPending,
      notes: json['notes'] as String?,
      changedByName: changerName,
      changedByEmail: changerEmail,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'old_status': oldStatus,
    'new_status': newStatus,
    'notes': notes,
    'changed_by': {'name': changedByName, 'email': changedByEmail},
    'created_at': createdAt?.toIso8601String(),
  };
}
