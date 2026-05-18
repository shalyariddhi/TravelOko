import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firebase_service.dart';
import '../services/map_service.dart';
import '../utils/cached_tile_layer.dart';

class CollaborativeTripScreen extends StatefulWidget {
  final String tripId;
  final String tripTitle;

  const CollaborativeTripScreen({
    super.key,
    required this.tripId,
    required this.tripTitle,
  });

  @override
  State<CollaborativeTripScreen> createState() =>
      _CollaborativeTripScreenState();
}

class _CollaborativeTripScreenState
    extends State<CollaborativeTripScreen> {
  final _firebaseService = FirebaseService();
  final _mapController = MapController();
  final _screenshotController = ScreenshotController();
  final _currentUid =
      FirebaseService().currentUserUid;

  // ── Add stop form controllers ───────────────
  final _titleController = TextEditingController();
  final _dayController = TextEditingController(text: '1');
  final _emailController = TextEditingController();
  bool _isAddingStop = false;
  bool _isInviting = false;

  Timer? _presenceTimer;

  @override
  void initState() {
    super.initState();
    _firebaseService.updateCursor(widget.tripId, null);
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _firebaseService.updateCursor(widget.tripId, null);
    });
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _firebaseService.clearCursor(widget.tripId);
    _titleController.dispose();
    _dayController.dispose();
    _emailController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── ADD STOP ────────────────────────────────
  void _showAddStopSheet() {
    _titleController.clear();
    _dayController.text = '1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStopSheet(
        titleController: _titleController,
        dayController: _dayController,
        isLoading: _isAddingStop,
        onSubmit: _addStop,
      ),
    );
  }

  Future<void> _addStop() async {
    final title = _titleController.text.trim();
    final day = int.tryParse(_dayController.text) ?? 1;
    if (title.isEmpty) return;

    setState(() => _isAddingStop = true);
    Navigator.pop(context);

    try {
      // Geocode the place name → real coordinates
      final enriched = await MapService.enrichPlace(title);
      final lat = enriched?['lat'] as double?;
      final lng = enriched?['lng'] as double?;

      await _firebaseService.addItineraryItem(widget.tripId, {
        'title': title,
        'day': day,
        'lat': lat,
        'lng': lng,
        'address': enriched?['address'] ?? title,
      });

      await _firebaseService.logActivity(
        tripId: widget.tripId,
        action: 'added stop',
        itemTitle: title,
      );

      if (mounted && lat != null && lng != null) {
        _mapController.move(LatLng(lat, lng), 13);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAddingStop = false);
    }
  }

  // ── INVITE MEMBER ────────────────────────────
  void _showInviteSheet() {
    _emailController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InviteSheet(
        emailController: _emailController,
        isLoading: _isInviting,
        onInvite: _inviteByEmail,
      ),
    );
  }

  Future<void> _inviteByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isInviting = true);
    Navigator.pop(context);

    try {
      final user = await _firebaseService.searchUserByEmail(email);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user found with that email.')),
          );
        }
        return;
      }

      await _firebaseService.addMember(widget.tripId, user['uid'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${user['name'] ?? email} added to the trip!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  // ── CHAT ────────────────────────────────
  void _showChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatSheet(
        tripId: widget.tripId,
        firebaseService: _firebaseService,
      ),
    );
  }

  // ── ACTIVITY ────────────────────────────────
  void _showActivitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivitySheet(
        tripId: widget.tripId,
        firebaseService: _firebaseService,
      ),
    );
  }

  // ── DELETE STOP ──────────────────────────────
  Future<void> _deleteStop(String itemId, String addedBy) async {
    // Only the person who added the stop can delete it
    if (addedBy != _currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can only delete your own stops.")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Stop',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('Remove this stop from the shared itinerary?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await _firebaseService.deleteItineraryItem(widget.tripId, itemId);
      await _firebaseService.logActivity(
        tripId: widget.tripId,
        action: 'deleted stop',
      );
    }
  }

  // ── EXPORT TO STORY ──────────────────────────────────────────────────────
  Future<void> _exportToStory() async {
    try {
      final Uint8List? image = await _screenshotController.capture(
        pixelRatio: 3.0, // High-res for Instagram Stories
      );
      if (image == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gotrivo_trip.png');
      await file.writeAsBytes(image);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '✈️ Check out my trip plan on GO-Trivo! 🗺️ #GOTrivo #TravelPlanning',
          subject: 'My Trip Plan – ${widget.tripTitle}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Screenshot(
          controller: _screenshotController,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tripTitle,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.getPresence(widget.tripId),
              builder: (context, snapshot) {
                final users = snapshot.data ?? [];
                return Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text('${users.length} active',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.green)),
                ]);
              },
            ),
          ],
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.deepPurple),
            tooltip: 'Export to Story',
            onPressed: _exportToStory,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.deepPurple),
            tooltip: 'Activity Timeline',
            onPressed: _showActivitySheet,
          )
,
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.deepPurple),
            tooltip: 'Trip Chat',
            onPressed: _showChatSheet,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: Colors.deepPurple),
            tooltip: 'Invite member',
            onPressed: _showInviteSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: _isAddingStop
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_location_alt),
        label: Text('Add Stop',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        onPressed: _isAddingStop ? null : _showAddStopSheet,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getItinerary(widget.tripId),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          // Build markers for items that have coordinates
          final markers = items.where((i) => i['lat'] != null && i['lng'] != null).toList();

          return Column(
            children: [
              // ── MAP ──────────────────────────────────────
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.38,
                child: FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(20.5937, 78.9629), // India
                    initialZoom: 5,
                  ),
                  children: [
                    cachedTileLayer(),
                    if (markers.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: markers.map((i) =>
                                LatLng(i['lat'], i['lng'])).toList(),
                            strokeWidth: 3,
                            color: Colors.deepPurple.withValues(alpha: 0.6),
                            pattern: const StrokePattern.dotted(),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: markers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final isOwn = item['addedBy'] == _currentUid;
                        return Marker(
                          point: LatLng(item['lat'], item['lng']),
                          width: 48,
                          height: 48,
                          child: Tooltip(
                            message: item['title'] ?? '',
                            child: CircleAvatar(
                              backgroundColor:
                                  isOwn ? Colors.deepPurple : Colors.teal,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // ── LEGEND ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _legendDot(Colors.deepPurple, 'My stops'),
                    const SizedBox(width: 16),
                    _legendDot(Colors.teal, "Teammate's stops"),
                    const Spacer(),
                    Text('${items.length} stop${items.length == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),

              // ── ITINERARY LIST ───────────────────────────
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isOwn =
                                  item['addedBy'] == _currentUid;
                              final hasCoords = item['lat'] != null &&
                                  item['lng'] != null;

                              return Dismissible(
                                key: Key(item['id'] ?? index.toString()),
                                direction: isOwn
                                    ? DismissDirection.endToStart
                                    : DismissDirection.none,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                ),
                                onDismissed: (_) => _deleteStop(
                                    item['id'] ?? '', item['addedBy'] ?? ''),
                                child: GestureDetector(
                                  onTap: () {
                                    if (hasCoords) {
                                      _mapController.move(
                                          LatLng(item['lat'], item['lng']),
                                          14);
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: isOwn
                                          ? Border.all(
                                              color: Colors.deepPurple
                                                  .withValues(alpha: 0.3))
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isOwn
                                            ? Colors.deepPurple
                                            : Colors.teal,
                                        radius: 18,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                      title: Text(
                                        item['title'] ?? 'Untitled',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (item['address'] != null)
                                            Text(item['address'],
                                                style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.grey),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          Row(children: [
                                            Icon(
                                              isOwn
                                                  ? Icons.person
                                                  : Icons.group,
                                              size: 12,
                                              color: isOwn
                                                  ? Colors.deepPurple
                                                  : Colors.teal,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isOwn
                                                  ? 'You · Day ${item['day'] ?? '?'}'
                                                  : '${item['addedByName'] ?? 'Teammate'} · Day ${item['day'] ?? '?'}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: isOwn
                                                      ? Colors.deepPurple
                                                      : Colors.teal),
                                            ),
                                          ]),
                                        ],
                                      ),
                                      trailing: hasCoords
                                          ? const Icon(
                                              Icons.map_outlined,
                                              color: Colors.grey,
                                              size: 18,
                                            )
                                          : const Icon(
                                              Icons.location_off,
                                              color: Colors.orange,
                                              size: 18,
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style:
              GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
    ]);
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No stops yet',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('Tap + Add Stop to build your shared itinerary',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ── ADD STOP SHEET ──────────────────────────────────────────────────────
class _AddStopSheet extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController dayController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _AddStopSheet({
    required this.titleController,
    required this.dayController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add_location_alt,
                  color: Colors.deepPurple, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Add a Stop',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text('Location will be geocoded automatically',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Taj Mahal, Agra',
              hintStyle: GoogleFonts.poppins(),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dayController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Day number',
              hintStyle: GoogleFonts.poppins(),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading ? null : onSubmit,
              child: Text('Add to Itinerary',
                  style:
                      GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── INVITE SHEET ────────────────────────────────────────────────────────
class _InviteSheet extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onInvite;

  const _InviteSheet({
    required this.emailController,
    required this.isLoading,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person_add_outlined,
                  color: Colors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Invite Collaborator',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text('Search by the member\'s account email',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'friend@email.com',
              hintStyle: GoogleFonts.poppins(),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading ? null : onInvite,
              child: Text('Send Invite',
                  style:
                      GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── CHAT SHEET ────────────────────────────────────────────────────────────
class _ChatSheet extends StatefulWidget {
  final String tripId;
  final FirebaseService firebaseService;

  const _ChatSheet({required this.tripId, required this.firebaseService});

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _msgController = TextEditingController();

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    await widget.firebaseService.sendMessage(widget.tripId, text);
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.chat_bubble_outline),
            const SizedBox(width: 8),
            Text('Trip Chat',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.firebaseService.getChat(widget.tripId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['userId'] == widget.firebaseService.currentUserUid;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.deepPurple : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(msg['userName'] ?? 'Traveler',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold)),
                          Text(msg['text'] ?? '',
                              style: GoogleFonts.poppins(
                                  color: isMe ? Colors.white : Colors.black87)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              left: 16, right: 16, top: 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.deepPurple),
              onPressed: _send,
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── ACTIVITY SHEET ──────────────────────────────────────────────────────────
class _ActivitySheet extends StatelessWidget {
  final String tripId;
  final FirebaseService firebaseService;

  const _ActivitySheet({required this.tripId, required this.firebaseService});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.history),
            const SizedBox(width: 8),
            Text('Activity Timeline',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: firebaseService.getActivity(tripId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final activities = snapshot.data ?? [];
              if (activities.isEmpty) {
                return Center(
                  child: Text('No activity yet',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final a = activities[index];
                  final time = a['createdAt'];
                  String timeStr = '';
                  if (time is Timestamp) {
                    final dt = time.toDate();
                    timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                  }
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.bolt, color: Colors.white, size: 16),
                    ),
                    title: Text('${a['userName']} ${a['action']}',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    subtitle: a['itemTitle'] != null
                        ? Text(a['itemTitle'],
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.bold))
                        : null,
                    trailing: Text(timeStr,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey)),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

