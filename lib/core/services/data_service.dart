import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';

class DataExportImportService {
  /// Exports the provided data map to a JSON file and opens the share sheet.
  static Future<void> exportToJson(Map<String, dynamic> data) async {
    try {
      final String jsonString = jsonEncode(data);
      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File file = File('${directory.path}/fintrack_backup_$timestamp.json');
      
      await file.writeAsString(jsonString);
      
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'FinTrack Pro Backup',
          text: 'My FinTrack Pro data backup from ${DateTime.now().toString()}',
        ),
      );
    } catch (e) {
      throw Exception('Failed to export JSON: $e');
    }
  }

  /// Exports a list of transactions to a CSV file and opens the share sheet.
  static Future<void> exportToCsv(List<TransactionModel> transactions) async {
    try {
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add(['ID', 'Date', 'Type', 'Category', 'Amount', 'Description']);
      
      for (var tx in transactions) {
        rows.add([
          tx.id,
          tx.date.toIso8601String(),
          tx.type.name,
          tx.category,
          tx.amount,
          tx.description,
        ]);
      }
      
      String csvData = csv.encode(rows);
      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File file = File('${directory.path}/fintrack_transactions_$timestamp.csv');
      
      await file.writeAsString(csvData);
      
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'FinTrack Pro Backup',
          text: 'My FinTrack Pro data backup from ${DateTime.now().toString()}',
        ),
      );
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  /// Opens a file picker and returns the JSON data as a Map.
  static Future<Map<String, dynamic>?> pickAndParseJson() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final String content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to parse JSON file: $e');
    }
  }

  /// Opens a file picker and returns a list of TransactionModel from a CSV.
  static Future<List<TransactionModel>?> pickAndParseCsv() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final String content = await file.readAsString();
        List<List<dynamic>> rows = csv.decode(content);
        
        if (rows.length <= 1) return []; // Header only or empty

        // Dynamic header mapping for robustness
        final List<dynamic> headers = rows[0].map((h) => h.toString().toLowerCase()).toList();
        final int idIdx = headers.indexOf('id');
        final int dateIdx = headers.indexOf('date');
        final int typeIdx = headers.indexOf('type');
        final int catIdx = headers.indexOf('category');
        final int amtIdx = headers.indexOf('amount');
        final int descIdx = headers.indexOf('description');

        List<TransactionModel> transactions = [];
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length < 5) continue; 

          // Fallback to indices if headers not found, otherwise use mapped index
          final id = idIdx != -1 ? row[idIdx] : row[0];
          final dateStr = dateIdx != -1 ? row[dateIdx] : row[1];
          final typeStr = typeIdx != -1 ? row[typeIdx] : row[2];
          final cat = catIdx != -1 ? row[catIdx] : row[3];
          final amt = amtIdx != -1 ? row[amtIdx] : row[4];
          final desc = descIdx != -1 ? (row.length > descIdx ? row[descIdx] : '') : '';

          transactions.add(TransactionModel(
            id: id.toString(),
            date: DateTime.tryParse(dateStr.toString()) ?? DateTime.now(),
            type: typeStr.toString().toLowerCase().contains('income') 
                ? TransactionType.income 
                : TransactionType.expense,
            category: cat.toString(),
            amount: double.tryParse(amt.toString()) ?? 0.0,
            description: desc.toString(),
          ));
        }
        return transactions;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to parse CSV file: $e');
    }
  }
}
