import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  static const LatLng _initialCenter = LatLng(-6.2000, 106.8166);

  final List<Marker> _markers = [
    Marker(
      point: const LatLng(-6.2000, 106.8166),
      width: 80,
      height: 80,
      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
    ),
    Marker(
      point: const LatLng(-6.2050, 106.8200),
      width: 80,
      height: 80,
      child: const Icon(Icons.local_pharmacy, color: Colors.blue, size: 40),
    ),
    Marker(
      point: const LatLng(-6.1950, 106.8100),
      width: 80,
      height: 80,
      child: const Icon(Icons.science, color: Colors.green, size: 40),
    ),
  ];

  int _activeCategoryIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tbconsult',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                _buildBackButton(context),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildCategoryChips(),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () {
                _mapController.move(_initialCenter, 13.0);
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: const TextField(
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Search clinics, pharmacies...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: Icon(Icons.tune, color: AppColors.textSecondary),
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chipItem(Icons.local_hospital, "Clinics", 0),
          const SizedBox(width: 8),
          _chipItem(Icons.local_pharmacy, "Pharmacies", 1),
          const SizedBox(width: 8),
          _chipItem(Icons.science, "Labs", 2),
        ],
      ),
    );
  }

  Widget _chipItem(IconData icon, String label, int index) {
    final isActive = _activeCategoryIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeCategoryIndex = _activeCategoryIndex == index ? -1 : index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
