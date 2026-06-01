import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:TBConsult/features/maps/domain/entities/facility_entity.dart';
import 'package:TBConsult/features/maps/domain/usecases/facility_usecases.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final GetFacilitiesUseCase getFacilitiesUseCase;
  final GetRouteUseCase getRouteUseCase;

  String? _pendingFacilityId;

  MapCubit({
    required this.getFacilitiesUseCase,
    required this.getRouteUseCase,
  }) : super(const MapInitial());

  // ── Initialise ──────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    emit(const MapLoading());
    try {
      final location = await _requestLocation();
      final facilities = await getFacilitiesUseCase(
        GetFacilitiesParams(userLocation: location),
      );
      
      FacilityEntity? selected;
      if (_pendingFacilityId != null) {
        try {
          selected = facilities.firstWhere((f) => f.id == _pendingFacilityId);
        } catch (_) {}
        _pendingFacilityId = null;
      }

      emit(MapLoaded(
        allFacilities: facilities,
        filteredFacilities: facilities,
        activeFilters: const {},
        searchQuery: '',
        userLocation: location,
        selectedFacility: selected,
      ));
    } catch (e) {
      emit(MapError(message: e.toString()));
    }
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  void search(String query) {
    final current = _loaded;
    if (current == null) return;
    final updated = current.copyWith(
      searchQuery: query,
      filteredFacilities: _applyFilters(
        current.allFacilities,
        current.activeFilters,
        query,
        current.maxDistanceKm,
        current.minRating,
      ),
      clearRoute: true,
      clearSelectedFacility: true,
    );
    emit(updated);
  }

  // ── Filters ─────────────────────────────────────────────────────────────────

  void setFilters({
    Set<FacilityType>? types,
    double? maxDistanceKm,
    double? minRating,
    bool clearMaxDistance = false,
  }) {
    final current = _loaded;
    if (current == null) return;

    final newTypes = types ?? current.activeFilters;
    final newMaxDistance = clearMaxDistance ? null : (maxDistanceKm ?? current.maxDistanceKm);
    final newMinRating = minRating ?? current.minRating;

    emit(current.copyWith(
      activeFilters: newTypes,
      maxDistanceKm: newMaxDistance,
      clearMaxDistance: clearMaxDistance,
      minRating: newMinRating,
      filteredFacilities: _applyFilters(
        current.allFacilities,
        newTypes,
        current.searchQuery,
        newMaxDistance,
        newMinRating,
      ),
      clearRoute: true,
      clearSelectedFacility: true,
    ));
  }

  // ── Facility selection ──────────────────────────────────────────────────────

  void selectFacility(FacilityEntity facility) {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(
      selectedFacility: facility,
      clearRoute: true,
    ));
  }

  void selectFacilityById(String id) {
    final current = _loaded;
    if (current == null) {
      _pendingFacilityId = id;
      return;
    }
    try {
      final facility = current.allFacilities.firstWhere((f) => f.id == id);
      emit(current.copyWith(
        selectedFacility: facility,
        clearRoute: true,
      ));
    } catch (_) {}
  }

  void clearSelection() {
    final current = _loaded;
    if (current == null) return;
    emit(current.copyWith(clearSelectedFacility: true, clearRoute: true));
  }

  // ── GPS ─────────────────────────────────────────────────────────────────────

  Future<void> recenterToUser() async {
    final current = _loaded;
    if (current?.userLocation != null) return; // already have it
    try {
      final location = await _requestLocation();
      if (current != null && location != null) {
        emit(current.copyWith(userLocation: location));
      }
    } catch (_) {}
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  MapLoaded? get _loaded {
    final s = state;
    if (s is MapLoaded) return s;
    return null;
  }

  List<FacilityEntity> _applyFilters(
      List<FacilityEntity> all,
      Set<FacilityType> filters,
      String query,
      double? maxDistanceKm,
      double minRating,
      ) {
    return all.where((f) {
      final matchesType = filters.isEmpty || filters.contains(f.type);
      final q = query.toLowerCase();
      final matchesQuery = q.isEmpty ||
          f.name.toLowerCase().contains(q) ||
          f.address.toLowerCase().contains(q);
      final matchesRating = f.rating >= minRating;
      final matchesDistance = maxDistanceKm == null ||
          (f.distanceKm != null && f.distanceKm! <= maxDistanceKm);
      return matchesType && matchesQuery && matchesRating && matchesDistance;
    }).toList();
  }

  Future<LatLng?> _requestLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
