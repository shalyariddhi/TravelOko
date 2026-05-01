import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

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

  void _addMockExpense() {
    setState(() {
      expenses.add(Expense(
        id: DateTime.now().toString(),
        title: 'Dinner',
        amount: 500,
        category: 'Food',
        date: DateTime.now(),
      ));
    });
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addMockExpense,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add),
      ),
    );
  }
}
