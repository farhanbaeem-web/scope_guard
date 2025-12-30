import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String title;
  final int outOfScopeCount;
  final int totalExtra;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.title,
    required this.outOfScopeCount,
    required this.totalExtra,
    required this.createdAt,
  });

  factory ReportModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReportModel(
      id: doc.id,
      title: (data['title'] ?? 'Scope Report').toString(),
      outOfScopeCount: (data['outOfScopeCount'] as num?)?.toInt() ?? 0,
      totalExtra: (data['totalExtra'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap({bool serverTimestamp = false}) {
    return {
      'title': title.trim(),
      'outOfScopeCount': outOfScopeCount,
      'totalExtra': totalExtra,
      'createdAt': serverTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
