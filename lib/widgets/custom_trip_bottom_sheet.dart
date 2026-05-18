import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/generated_plan_screen.dart';
import '../services/places_api_service.dart';

class CustomTripBottomSheet extends StatefulWidget {
  final String? initialDestination;
  const CustomTripBottomSheet({super.key, this.initialDestination});

  @override
  State<CustomTripBottomSheet> createState() => _CustomTripBottomSheetState();
}

class _CustomTripBottomSheetState extends State<CustomTripBottomSheet> {
  final _budgetController = TextEditingController(text: '15000');
  final _destinationController = TextEditingController();
  final PlacesApiService _placesApiService = PlacesApiService();
  
  int _travelers = 2;
  double _days = 3;
  String _selectedStyle = 'Relaxing';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _destinationController.text = widget.initialDestination!;
    }
  }

  // Comprehensive list of Indian cities
  static final List<String> _allIndiaCities = [
    'Agartala', 'Agra', 'Ahmedabad', 'Aizawl', 'Ajmer', 'Akola', 'Aligarh',
    'Allahabad', 'Alappuzha', 'Alwar', 'Ambala', 'Amravati', 'Amritsar',
    'Anand', 'Anantapur', 'Andaman Islands', 'Asansol', 'Aurangabad',
    'Badami', 'Bagdogra', 'Bangalore', 'Bareilly', 'Bathinda', 'Belagavi',
    'Bhagalpur', 'Bharatpur', 'Bhopal', 'Bhubaneswar', 'Bidar', 'Bikaner',
    'Bilaspur', 'Bokaro', 'Chandigarh', 'Chennai', 'Chhatarpur',
    'Chikmagalur', 'Coimbatore', 'Coorg', 'Cuttack',
    'Dahanu', 'Darjeeling', 'Dehradun', 'Delhi', 'Dharamshala', 'Diu',
    'Durgapur', 'Dwarka',
    'Ernakulam', 'Erode',
    'Faridabad', 'Fatehpur Sikri', 'Gangtok', 'Gaya', 'Goa', 'Gorakhpur',
    'Gulbarga', 'Guntur', 'Gurgaon', 'Guwahati', 'Gwalior',
    'Hampi', 'Haridwar', 'Hassan', 'Hisar', 'Hospet', 'Hubli', 'Hyderabad',
    'Imphal', 'Indore', 'Itanagar',
    'Jabalpur', 'Jaipur', 'Jaisalmer', 'Jalandhar', 'Jammu', 'Jamnagar',
    'Jamshedpur', 'Jodhpur', 'Jorhat',
    'Kakinada', 'Kalimpong', 'Kanpur', 'Karaikudi', 'Karimnagar', 'Kasauli',
    'Katra', 'Khajuraho', 'Kochi', 'Kodaikanal', 'Kohima', 'Kolhapur',
    'Kolkata', 'Kollam', 'Kota', 'Kottayam', 'Kozhikode', 'Kumbakonam',
    'Kutch',
    'Ladakh', 'Lakshadweep', 'Leh', 'Lucknow', 'Ludhiana',
    'Madurai', 'Mahabaleshwar', 'Mahabalipuram', 'Mangalore', 'Manali',
    'Meerut', 'Moradabad', 'Mount Abu', 'Mumbai', 'Munnar', 'Mysore',
    'Nagpur', 'Nainital', 'Nashik', 'Nathdwara', 'Navi Mumbai', 'Noida',
    'Ooty', 'Orchha',
    'Palakkad', 'Panaji', 'Patna', 'Patiala', 'Pondicherry', 'Port Blair',
    'Pune', 'Puri', 'Pushkar',
    'Raipur', 'Rajahmundry', 'Rajkot', 'Rameshwaram', 'Ranchi', 'Rishikesh',
    'Roorkee', 'Rourkela',
    'Salem', 'Samode', 'Shillong', 'Shimla', 'Siliguri', 'Silvassa',
    'Somnath', 'Srinagar', 'Surat', 'Surendranagar',
    'Thrissur', 'Thiruvananthapuram', 'Tirupati', 'Tiruchirapalli',
    'Tirunelveli', 'Trichur', 'Trichy', 'Tumkur',
    'Udaipur', 'Ujjain', 'Udupi',
    'Vadodara', 'Vapi', 'Varanasi', 'Vellore', 'Vijayawada', 'Visakhapatnam',
    'Warangal', 'Wardha',
    'Yamunanagar',
  ];

  final List<String> _tripStyles = ['Relaxing', 'Adventure', 'Cultural', 'Party'];

  @override
  void dispose() {
    _budgetController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or type a destination')),
      );
      return;
    }

    final budgetText = _budgetController.text.trim();
    final budget = int.tryParse(budgetText) ?? 0;
    
    if (budget < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget (min ₹1000)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final requestData = {
      'destination': destination,
      'budgetPerPerson': budget,
      'travelersCount': _travelers,
      'days': _days.toInt(),
      'style': _selectedStyle,
      'status': 'pending',
    };

    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeneratedPlanScreen(requestData: requestData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add padding for keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Plan Your Custom Trip',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us where you want to go, and we\'ll build the perfect itinerary for you.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Destination
            Text(
              'Where to?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                final query = textEditingValue.text.trim();
                if (query.isEmpty) {
                  return _allIndiaCities; // show full list on tap
                }
                // First filter local list
                final localMatches = _allIndiaCities.where(
                  (city) => city.toLowerCase().startsWith(query.toLowerCase()),
                ).toList();
                if (localMatches.isNotEmpty) return localMatches;
                // Fallback: live Google Places results
                return await _placesApiService.fetchAutocomplete(query);
              },
              onSelected: (String selection) {
                _destinationController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                // Keep controllers in sync so we can grab the text during submission
                if (_destinationController.text != controller.text && !focusNode.hasFocus) {
                  controller.text = _destinationController.text;
                }
                controller.addListener(() {
                  _destinationController.text = controller.text;
                });
                
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: 'Tap to browse or search...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.amber),
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.amber),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.amber, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 48,
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Text(option, style: GoogleFonts.poppins(fontSize: 15)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Budget
            Text(
              'Max Budget (Per Person)',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber[700]),
                hintText: 'e.g. 15000',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),

            // Travelers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Travelers',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: _travelers > 1 ? () => setState(() => _travelers--) : null,
                        color: _travelers > 1 ? Colors.black87 : Colors.grey,
                      ),
                      Text(
                        '$_travelers',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: _travelers < 20 ? () => setState(() => _travelers++) : null,
                        color: _travelers < 20 ? Colors.black87 : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Number of Days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duration',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text(
                  '${_days.toInt()} Days',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber[700]),
                ),
              ],
            ),
            Slider(
              value: _days,
              min: 2,
              max: 14,
              divisions: 12,
              activeColor: Colors.amber,
              onChanged: (v) => setState(() => _days = v),
            ),
            const SizedBox(height: 24),

            // Trip Style
            Text(
              'Trip Style',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _tripStyles.map((style) {
                final isSelected = _selectedStyle == style;
                return ChoiceChip(
                  label: Text(style, style: GoogleFonts.poppins(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStyle = style);
                  },
                  selectedColor: Colors.amber,
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(color: isSelected ? Colors.black87 : Colors.grey[700]),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                      )
                    : Text(
                        'Generate My Plan',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
