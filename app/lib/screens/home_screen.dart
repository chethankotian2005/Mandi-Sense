import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/compare_request.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'results_screen.dart';
import 'roadmap_screen.dart';

/// Entry screen: select crop, enter quantity, get location, compare.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  final _quantityController = TextEditingController(text: '500');

  List<String> _crops = [];
  String? _selectedCrop;
  double? _latitude;
  double? _longitude;
  bool _loadingCrops = true;
  bool _loadingLocation = false;
  String? _locationNote;

  // Default fallback: Udupi district center
  static const double _defaultLat = 13.3409;
  static const double _defaultLon = 74.7421;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    final crops = await _apiService.fetchCrops();
    setState(() {
      _crops = crops;
      if (crops.isNotEmpty) _selectedCrop = crops.first;
      _loadingCrops = false;
    });
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationNote = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fallbackLocation('Location services are disabled');
        return;
      }

      // Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _fallbackLocation('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _fallbackLocation('Location permission permanently denied');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        // For the hackathon demo, we'll override the real location to be near Udupi 
        // so the seeded markets are always found within the 50km radius.
        // Otherwise, testing from outside India results in a 404 Not Found.
        _latitude = _defaultLat + 0.02; // slight offset so it's not exactly 0.0km
        _longitude = _defaultLon + 0.02;
        _loadingLocation = false;
        _locationNote =
            'Demo: Location forced to Udupi region (Real: ${position.latitude.toStringAsFixed(1)}, ${position.longitude.toStringAsFixed(1)})';
      });
    } catch (e) {
      _fallbackLocation('Could not get location');
    }
  }

  void _fallbackLocation(String reason) {
    setState(() {
      _latitude = _defaultLat;
      _longitude = _defaultLon;
      _loadingLocation = false;
      _locationNote = '$reason — using Udupi as default';
    });
  }

  void _compareMarkets() {
    final quantity = double.tryParse(_quantityController.text);
    if (_selectedCrop == null || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop and enter a valid quantity.')),
      );
      return;
    }

    // If no location set yet, use default
    final lat = _latitude ?? _defaultLat;
    final lon = _longitude ?? _defaultLon;

    final request = CompareRequest(
      cropName: _selectedCrop!,
      quantityKg: quantity,
      farmerLatitude: lat,
      farmerLongitude: lon,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(request: request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco, color: AppTheme.accentAmber),
            const SizedBox(width: 8),
            Text('app_name'.tr()),
          ],
        ),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: 'Change Language',
            onSelected: (Locale locale) {
              context.setLocale(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              const PopupMenuItem<Locale>(
                value: Locale('en'),
                child: Text('English'),
              ),
              const PopupMenuItem<Locale>(
                value: Locale('hi'),
                child: Text('हिंदी (Hindi)'),
              ),
              const PopupMenuItem<Locale>(
                value: Locale('kn'),
                child: Text('ಕನ್ನಡ (Kannada)'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              context.watch<SettingsProvider>().isSimpleMode 
                  ? Icons.accessibility 
                  : Icons.accessibility_new,
            ),
            tooltip: 'Toggle Simple Mode',
            onPressed: () {
              context.read<SettingsProvider>().toggleSimpleMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'roadmap.title'.tr(),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoadmapScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ───────────────────────────────────────
              Text('home.header_title'.tr(), style: AppTheme.headline),
              const SizedBox(height: 4),
              Text(
                'home.header_subtitle'.tr(),
                style: AppTheme.bodySecondary,
              ),
              const SizedBox(height: 28),

              // ── Crop Selector ────────────────────────────────
              Text('home.select_crop'.tr(), style: AppTheme.title),
              const SizedBox(height: 8),
              _loadingCrops
                  ? const Center(child: CircularProgressIndicator())
                  : context.watch<SettingsProvider>().isSimpleMode
                      ? _buildSimpleCropSelector()
                      : Container(
                          decoration: AppTheme.cardDecoration(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCrop,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down),
                              items: _crops
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text('crops.$c'.tr(), style: AppTheme.body),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCrop = v),
                            ),
                          ),
                        ),
              const SizedBox(height: 24),

              // ── Quantity Input ───────────────────────────────
              Text('home.quantity_kg'.tr(), style: AppTheme.title),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                style: AppTheme.body,
                decoration: InputDecoration(
                  hintText: 'home.enter_quantity'.tr(),
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 24),

              // ── Location ────────────────────────────────────
              Text('home.location'.tr(), style: AppTheme.title),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loadingLocation ? null : _useMyLocation,
                icon: _loadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _loadingLocation
                      ? 'home.loading'.tr()
                      : 'home.use_my_location'.tr(),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.cardRadius),
                  ),
                ),
              ),
              if (_locationNote != null) ...[
                const SizedBox(height: 8),
                Text(_locationNote!, style: AppTheme.caption),
              ],
              const SizedBox(height: 32),

              // ── Compare Button ──────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _compareMarkets,
                  icon: const Icon(Icons.compare_arrows, size: 22),
                  label: Text('home.compare_options'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    textStyle: AppTheme.title.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Widget _buildSimpleCropSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _crops.map((c) {
        final isSelected = c == _selectedCrop;
        String emoji = "🌾";
        if (c == "Tomato") emoji = "🍅";
        if (c == "Onion") emoji = "🧅";
        if (c == "Potato") emoji = "🥔";
        
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCrop = c),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.dividerColor,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    'crops.$c'.tr(),
                    style: AppTheme.title.copyWith(
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
