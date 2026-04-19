import 'dart:convert';
import 'package:uuid/uuid.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String description;

  TransactionModel({
    String? id,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.description = '',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'category': category,
      'description': description,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      category: map['category'],
      description: map['description'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionModel.fromJson(String source) => TransactionModel.fromMap(json.decode(source));
}
