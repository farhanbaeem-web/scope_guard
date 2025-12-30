// lib/features/clients/data/client_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String id;
  final String name;
  final String project;
  final String contractType;
  final DateTime createdAt;

  // Premium / future-ready fields (optional)
  final String? notes;
  final bool risky;
  final int totalRequests;
  final int outOfScopeCount;

  ClientModel({
    required this.id,
    required this.name,
    required this.project,
    required this.contractType,
    required this.createdAt,
    this.notes,
    this.risky = false,
    this.totalRequests = 0,
    this.outOfScopeCount = 0,
  });

  factory ClientModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ClientModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      project: (data['project'] ?? '').toString(),
      contractType: (data['contractType'] ?? '').toString(),
      createdAt: _parseDate(data['createdAt']),
      notes: data['notes'] as String?,
      risky: (data['risky'] as bool?) ?? false,
      totalRequests: (data['totalRequests'] as num?)?.toInt() ?? 0,
      outOfScopeCount: (data['outOfScopeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap({bool serverTimestamp = false}) {
    return {
      'name': name,
      'project': project,
      'contractType': contractType,
      'createdAt':
          serverTimestamp ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),

      // Optional fields (only written if used)
      if (notes != null) 'notes': notes,
      'risky': risky,
      'totalRequests': totalRequests,
      'outOfScopeCount': outOfScopeCount,
    };
  }

  /// Helper: safe DateTime parsing
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
