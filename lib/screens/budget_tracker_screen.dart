import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/logger.dart';

class BudgetTrackerScreen extends StatefulWidget {
  final Trip trip;
  const BudgetTrackerScreen({super.key, required this.trip});

  @override
  State<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends State<BudgetTrackerScreen> {
  late List<Expense> expenses;

  @override
  void initState() {
    super.initState();
    expenses = List.from(widget.trip.expenses);
  }

  double get totalSpent => expenses.fold(0, (sum, item) => sum + item.amount);
  double get remainingBudget => widget.trip.budget - totalSpent;

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile == null) return;
    
    if (!mounted) return;
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      double maxAmount = 0.0;
      
      // Simple regex to find decimal numbers (e.g., 12.50, 450, 1,200.00)
      final RegExp amountRegex = RegExp(r'\b\d+(?:,\d{3})*(?:\.\d{1,2})?\b');
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final matches = amountRegex.allMatches(line.text);
          for (final match in matches) {
            final valStr = match.group(0)?.replaceAll(',', '') ?? '0';
            final val = double.tryParse(valStr) ?? 0.0;
            if (val > maxAmount) {
              maxAmount = val; // Often the total is the largest number on a receipt
            }
          }
        }
      }
      
      await textRecognizer.close();
      if (!mounted) return;
      Navigator.pop(context); // close loader
      
      _showAddExpenseDialog(initialAmount: maxAmount > 0 ? maxAmount : null);
      
    } catch (e) {
      appLogger.e("Error scanning receipt: $e");
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to read receipt')));
    }
  }

  void _showAddExpenseDialog({double? initialAmount}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController(text: initialAmount?.toStringAsFixed(2) ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Expense', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title (e.g. Dinner)'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee, size: 16)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (title.isNotEmpty && amount > 0) {
                setState(() {
                  expenses.add(Expense(
                    id: DateTime.now().toString(),
                    title: title,
                    amount: amount,
                    category: 'Scanned',
                    date: DateTime.now(),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Tracker', style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Text('Total Budget: ₹${NumberFormat('#,##,###').format(widget.trip.budget)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: widget.trip.budget > 0 ? (totalSpent / widget.trip.budget).clamp(0.0, 1.0) : 0,
                  backgroundColor: Colors.grey[300],
                  color: remainingBudget >= 0 ? Colors.green : Colors.red,
                  minHeight: 10,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Spent: ₹${NumberFormat('#,##,###').format(totalSpent)}', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
                    Text('Left: ₹${NumberFormat('#,##,###').format(remainingBudget)}', style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: expenses.isEmpty
                ? Center(child: Text('No expenses yet.', style: GoogleFonts.poppins(color: Colors.grey)))
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.receipt, color: Colors.white)),
                        title: Text(expense.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(expense.date)),
                        trailing: Text('₹${NumberFormat('#,##,###').format(expense.amount)}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scanFab',
            onPressed: _scanReceipt,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.document_scanner),
            label: const Text('Scan Receipt'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'manualFab',
            onPressed: () => _showAddExpenseDialog(),
            backgroundColor: Colors.amber,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
