import 'dart:async';

import 'package:TBConsult/core/di/injection_container.dart';
import 'package:TBConsult/features/maps/data/data_sources/facility_photo_service.dart';
import 'package:TBConsult/features/maps/presentation/widgets/map_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:TBConsult/core/theme/app_colors.dart';
import 'package:TBConsult/features/maps/domain/entities/facility_entity.dart';
import 'package:TBConsult/features/maps/presentation/cubit/map_cubit.dart';
import 'package:TBConsult/features/maps/presentation/cubit/map_state.dart';
import 'package:TBConsult/features/maps/presentation/widgets/facility_detail_sheet.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchCtrl = TextEditingController();

  static const _surabayaCenter = LatLng(-7.2575, 112.7521);
  static const _initialZoom = 12.5;

  // ── Marker BitmapDescriptors ─────────────────────────────────────────
  final Map<FacilityType, BitmapDescriptor> _markerIcons = {};

  FacilityEntity? _lastSelectedFacility;

  @override
  void initState() {
    super.initState();
    context.read<MapCubit>().initialize();
    _loadMarkerIcons();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMarkerIcons() async {
    // Use default hue-tinted markers matching each facility type
    _markerIcons[FacilityType.hospital] = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
    _markerIcons[FacilityType.clinic] = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueGreen,
    );
    _markerIcons[FacilityType.pharmacy] = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueOrange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapCubit, MapState>(
      listener: _onStateChange,
      builder: (context, state) {
        return Stack(
          children: [
            // ── Google Map ────────────────────────────────────────
            Positioned.fill(child: _buildMap(state)),

            // ── Top overlay: search + chips ───────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  _buildSearchBar(state),
                  const SizedBox(height: 10),
                  _buildChips(state),
                ],
              ),
            ),

            // ── My location FAB ───────────────────────────────────
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _recenterToUser,
                child: const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),

            // ── Loading overlay ───────────────────────────────────
            if (state is MapLoading)
              Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(child: CircularProgressIndicator()),
              ),

            // ── Error overlay ─────────────────────────────────────
            if (state is MapError)
              Container(
                color: Colors.white.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal memuat peta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          (state).message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.read<MapCubit>().initialize(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Map widget ────────────────────────────────────────────────────────

  Widget _buildMap(MapState state) {
    Set<Polyline> polylines = {};
    Set<Marker> markers = {};
    LatLng? userLocation;

    if (state is MapLoaded) {
      userLocation = state.userLocation;
      markers = _buildFacilityMarkers(state.filteredFacilities);

      if (state.userLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('_user'),
            position: state.userLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            ),
            infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          ),
        );
      }

      if (state.routePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: state.routePoints,
            color: AppColors.primary,
            width: 4,
            patterns: [],
          ),
        );
      }
    }

    // Wrap in a SizedBox.expand to ensure GoogleMap fills available space
    return SizedBox.expand(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: userLocation ?? _surabayaCenter,
          zoom: _initialZoom,
        ),
        onMapCreated: (c) {
          if (!_mapController.isCompleted) {
            _mapController.complete(c);
          }
        },
        markers: markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onTap: (_) => context.read<MapCubit>().clearSelection(),
      ),
    );
  }

  Set<Marker> _buildFacilityMarkers(List<FacilityEntity> facilities) {
    return facilities.map((facility) {
      return Marker(
        markerId: MarkerId(facility.id),
        position: LatLng(facility.lat, facility.lng),
        icon: _markerIcons[facility.type] ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: facility.name,
          snippet: facility.type.label,
        ),
        onTap: () {
          context.read<MapCubit>().selectFacility(facility);
        },
      );
    }).toSet();
  }

  // ── Search bar ────────────────────────────────────────────────────────

  Widget _buildSearchBar(MapState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (q) => context.read<MapCubit>().search(q),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Search clinics, pharmacies...',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          prefixIcon: IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textSecondary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textSecondary),
            onPressed: () => _showFilterSheet(state),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ── Type chips ────────────────────────────────────────────────────────

  Widget _buildChips(MapState state) {
    Set<FacilityType> active = {};
    if (state is MapLoaded) active = state.activeFilters;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FacilityType.values.map((type) {
          final isActive = active.isEmpty || active.contains(type);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                final newFilters = Set<FacilityType>.from(active);
                if (active.isEmpty) {
                  // Was showing all → activate only this type
                  newFilters.addAll(FacilityType.values);
                  newFilters.remove(type);
                } else if (newFilters.contains(type)) {
                  newFilters.remove(type);
                  if (newFilters.isEmpty) {
                    context.read<MapCubit>().setFilters(types: {});
                    return;
                  }
                } else {
                  newFilters.add(type);
                  if (newFilters.length == FacilityType.values.length) {
                    context.read<MapCubit>().setFilters(types: {});
                    return;
                  }
                }
                context.read<MapCubit>().setFilters(types: newFilters);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _chipIcon(type),
                      size: 16,
                      color: isActive ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.filterLabel,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── State listener ────────────────────────────────────────────────────

  Future<void> _onStateChange(BuildContext context, MapState state) async {
    if (state is MapError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }

    if (state is MapLoaded) {
      if (state.selectedFacility != null &&
          state.selectedFacility != _lastSelectedFacility) {
        _lastSelectedFacility = state.selectedFacility;
        final ctrl = await _mapController.future;
        await ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(state.selectedFacility!.lat, state.selectedFacility!.lng),
            15.0,
          ),
        );
        _showDetailSheet(state.selectedFacility!);
      } else if (state.selectedFacility == null) {
        _lastSelectedFacility = null;
      }

      if (state.routePoints.isNotEmpty) {
        // Zoom to fit the route
        await _fitPolylineBounds(state.routePoints);
      } else if (state.userLocation != null && state.selectedFacility == null) {
        // On first load, animate to user
        final ctrl = await _mapController.future;
        await ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(state.userLocation!, 13),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Future<void> _fitPolylineBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    final ctrl = await _mapController.future;
    await ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> _recenterToUser() async {
    final cubit = context.read<MapCubit>();
    await cubit.recenterToUser();
    final s = cubit.state;
    LatLng? loc;
    if (s is MapLoaded) loc = s.userLocation;
    if (loc != null) {
      final ctrl = await _mapController.future;
      await ctrl.animateCamera(CameraUpdate.newLatLngZoom(loc, 14));
    }
  }

  void _showDetailSheet(FacilityEntity facility) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MapCubit>(),
        child: FacilityDetailSheet(
          facility: facility,
          photoService: sl<FacilityPhotoService>(),
        ),
      ),
    ).then((_) {
      if (mounted) {
        context.read<MapCubit>().clearSelection();
      }
    });
  }

  void _showFilterSheet(MapState state) {
    Set<FacilityType> current = {};
    double? currentMaxDistance;
    double currentMinRating = 0.0;

    if (state is MapLoaded) {
      current = state.activeFilters;
      currentMaxDistance = state.maxDistanceKm;
      currentMinRating = state.minRating;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MapFilterSheet(
        initialFilters: current,
        initialMaxDistance: currentMaxDistance,
        initialMinRating: currentMinRating,
        onApply: (filters, maxDist, minRat) =>
            context.read<MapCubit>().setFilters(
              types: filters,
              maxDistanceKm: maxDist,
              clearMaxDistance: maxDist == null,
              minRating: minRat,
            ),
      ),
    );
  }

  IconData _chipIcon(FacilityType type) {
    switch (type) {
      case FacilityType.hospital:
        return Icons.local_hospital_outlined;
      case FacilityType.clinic:
        return Icons.medical_services_outlined;
      case FacilityType.pharmacy:
        return Icons.local_pharmacy_outlined;
    }
  }
}
