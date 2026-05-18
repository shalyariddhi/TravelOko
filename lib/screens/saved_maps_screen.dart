import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_map_screen.dart';

class SavedMapsScreen extends StatefulWidget {
  const SavedMapsScreen({super.key});

  @override
  State<SavedMapsScreen> createState() => _SavedMapsScreenState();
}

class _SavedMapsScreenState extends State<SavedMapsScreen> {
  List<Map<String, dynamic>> _savedMaps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedMaps();
  }

  Future<void> _loadSavedMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('saved_maps') ?? [];
    setState(() {
      _savedMaps = raw
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList(); // newest first
      _isLoading = false;
    });
  }

  Future<void> _deleteMap(int index) async {
    final prefs = await SharedPreferences.getInstance();
    // The list is reversed in memory, so get the actual index
    final raw = prefs.getStringList('saved_maps') ?? [];
    final actualIndex = raw.length - 1 - index;
    raw.removeAt(actualIndex);
    await prefs.setStringList('saved_maps', raw);
    setState(() => _savedMaps.removeAt(index));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline map removed')),
      );
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'Unknown date';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Saved Offline Maps',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _savedMaps.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No Saved Maps',
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Save Map" on any location\nto store it for offline use.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _savedMaps.length,
      itemBuilder: (context, index) {
        final map = _savedMaps[index];
        final name = map['name'] ?? 'Unknown Location';
        final savedAt = _formatDate(map['savedAt']);
        final image = map['image'] as String?;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationMapScreen(
                  locationData: map,
                  isOfflineMode: true,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  image != null
                      ? Image.network(image, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1A2E44),
                          ))
                      : Container(color: const Color(0xFF1A2E44)),

                  // Dark overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.offline_pin, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'OFFLINE READY',
                              style: GoogleFonts.poppins(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white60, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Saved $savedAt',
                              style: GoogleFonts.poppins(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _confirmDelete(index, name),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().slideX(begin: 0.3, end: 0, duration: 400.ms, delay: (index * 60).ms, curve: Curves.easeOut).fadeIn(duration: 300.ms, delay: (index * 60).ms),
        );
      },
    );
  }

  void _confirmDelete(int index, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E44),
        title: Text('Delete Map?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Remove the offline map for "$name"?',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMap(index);
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
