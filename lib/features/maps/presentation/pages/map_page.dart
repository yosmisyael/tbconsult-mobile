import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(-6.2000, 106.8166),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tbcare.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(-6.2000, 106.8166),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.medical_services, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildCategoryChips(),
              ],
            ),
          ),

          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () {},
              child: const Icon(Icons.layers, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: const TextField(
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Search clinics, pharmacies...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: Icon(Icons.tune, color: AppColors.textSecondary,),
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
          _chipItem(Icons.local_hospital, "Clinics", false),
          const SizedBox(width: 8),
          _chipItem(Icons.local_pharmacy, "Pharmacies", true), // Active
          const SizedBox(width: 8),
          _chipItem(Icons.science, "Labs", false),
        ],
      ),
    );
  }

  Widget _chipItem(IconData icon, String label, bool isActive) {
    return Container(
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
          Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}