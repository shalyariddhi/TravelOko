import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trip.dart';
import '../models/packing_item.dart';

class PackingChecklistScreen extends StatefulWidget {
  final Trip trip;
  const PackingChecklistScreen({super.key, required this.trip});

  @override
  State<PackingChecklistScreen> createState() => _PackingChecklistScreenState();
}

class _PackingChecklistScreenState extends State<PackingChecklistScreen> {
  late List<PackingItem> items;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.trip.packingList);
    if (items.isEmpty) {
      items = [
        PackingItem(id: '1', name: 'Passport', category: 'Documents'),
        PackingItem(id: '2', name: 'Toothbrush', category: 'Toiletries'),
        PackingItem(id: '3', name: 'Phone Charger', category: 'Electronics'),
      ];
    }
  }

  void _addMockItem() {
    setState(() {
      items.add(PackingItem(id: DateTime.now().toString(), name: 'New Item', category: 'General'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Packing Checklist', style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return CheckboxListTile(
            title: Text(item.name, style: GoogleFonts.poppins(decoration: item.isPacked ? TextDecoration.lineThrough : null)),
            subtitle: Text(item.category, style: GoogleFonts.poppins(fontSize: 12)),
            value: item.isPacked,
            onChanged: (bool? value) {
              setState(() {
                item.isPacked = value ?? false;
              });
            },
            activeColor: Colors.amber,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMockItem,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add),
      ),
    );
  }
}
