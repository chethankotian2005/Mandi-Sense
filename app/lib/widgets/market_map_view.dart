import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/market_result.dart';
import '../theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

class MarketMapView extends StatefulWidget {
  final double farmerLat;
  final double farmerLng;
  final List<MarketComparisonResult> markets;

  const MarketMapView({
    super.key,
    required this.farmerLat,
    required this.farmerLng,
    required this.markets,
  });

  @override
  State<MarketMapView> createState() => _MarketMapViewState();
}

class _MarketMapViewState extends State<MarketMapView> {
  MarketComparisonResult? _selectedMarket;

  @override
  Widget build(BuildContext context) {
    // Generate markers
    final markers = <Marker>[];

    // Farmer marker (Blue dot)
    markers.add(
      Marker(
        point: LatLng(widget.farmerLat, widget.farmerLng),
        width: 40,
        height: 40,
        child: const Icon(
          Icons.person_pin_circle,
          color: Colors.blue,
          size: 40,
        ),
      ),
    );

    // Market markers
    for (int i = 0; i < widget.markets.length; i++) {
      final market = widget.markets[i];
      final isBest = i == 0;
      final color = isBest ? AppTheme.primaryGreen : AppTheme.accentAmber;

      markers.add(
        Marker(
          point: LatLng(market.latitude, market.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMarket = market;
              });
            },
            child: Icon(
              Icons.location_on,
              color: color,
              size: 40,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(widget.farmerLat, widget.farmerLng),
            initialZoom: 9.0, // Appropriate for ~50km radius
            onTap: (_, __) {
              // Deselect if tapped elsewhere on map
              if (_selectedMarket != null) {
                setState(() {
                  _selectedMarket = null;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mandisense',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        
        // Popup overlay
        if (_selectedMarket != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.cardDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedMarket!.marketName, style: AppTheme.title),
                        const SizedBox(height: 2),
                        Text(
                          'results.km_away'.tr(namedArgs: {
                            'dist': _selectedMarket!.distanceKm.toStringAsFixed(1)
                          }),
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\u20B9${_selectedMarket!.netReturn.toStringAsFixed(0)}',
                    style: AppTheme.bigNumber.copyWith(
                      fontSize: 20,
                      color: _selectedMarket == widget.markets[0]
                          ? AppTheme.primaryGreen
                          : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
