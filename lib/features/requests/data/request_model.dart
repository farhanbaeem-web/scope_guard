import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String title;
  final String description;
  final bool inScope;
  final String approvalStatus;
  final int? estimatedCost;
  final DateTime createdAt;

  const RequestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.inScope,
    this.approvalStatus = 'none',
    this.estimatedCost,
    required this.createdAt,
  });

  factory RequestModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError('Request document is empty');
    }

    return RequestModel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      inScope: (data['inScope'] as bool?) ?? true,
      approvalStatus: (data['approvalStatus'] ?? 'none').toString(),
      estimatedCost: data['estimatedCost'] is num
          ? (data['estimatedCost'] as num).toInt()
          : null,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'inScope': inScope,
      'approvalStatus': approvalStatus,
      'estimatedCost': estimatedCost,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toMapWithServerTimestamp() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'inScope': inScope,
      'approvalStatus': approvalStatus,
      'estimatedCost': estimatedCost,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Useful when editing a request
  RequestModel copyWith({
    String? title,
    String? description,
    bool? inScope,
    String? approvalStatus,
    int? estimatedCost,
  }) {
    return RequestModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      inScope: inScope ?? this.inScope,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      createdAt: createdAt,
    );
  }
}
