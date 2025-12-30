import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { info, success, warning, danger }

class ActivityModel {
  final String id;
  final String title;
  final String detail;
  final ActivityType type;
  final DateTime createdAt;
  final String? clientId;
  final String? requestId;

  const ActivityModel({
    required this.id,
    required this.title,
    required this.detail,
    required this.type,
    required this.createdAt,
    this.clientId,
    this.requestId,
  });

  factory ActivityModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityModel(
      id: doc.id,
      title: (data['title'] ?? 'Activity').toString(),
      detail: (data['detail'] ?? '').toString(),
      type: _parseType(data['type']),
      createdAt: _parseDate(data['createdAt']),
      clientId: data['clientId'] as String?,
      requestId: data['requestId'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool serverTimestamp = false}) {
    return {
      'title': title.trim(),
      'detail': detail.trim(),
      'type': type.name,
      'createdAt': serverTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      if (clientId != null) 'clientId': clientId,
      if (requestId != null) 'requestId': requestId,
    };
  }

  static ActivityType _parseType(dynamic value) {
    final v = value?.toString() ?? '';
    return ActivityType.values.firstWhere(
      (t) => t.name == v,
      orElse: () => ActivityType.info,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
