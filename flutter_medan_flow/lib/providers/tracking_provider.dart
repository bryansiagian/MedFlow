import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class TrackingProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  bool _isTracking = false;
  int? _currentTripId;

  bool get isTracking => _isTracking;

  Future<void> toggleTracking() async {
    if (_isTracking) {
      await _stopTracking(); // ← await agar endTrip selesai dulu
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    try {
      // 1. Cek & Minta Izin Lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      // Handle semua kondisi penolakan
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('❌ Izin lokasi ditolak');
        return;
      }

      // 2. Panggil API Start Trip
      _currentTripId = await _apiService.startTrip();
      if (_currentTripId == null) {
        debugPrint('❌ Gagal mendapat trip_id');
        return;
      }

      _isTracking = true;
      notifyListeners();

      // 3. Kirim lokasi langsung sekali, tidak perlu tunggu 10 detik pertama
      await _sendLocation();

      // 4. Lanjut kirim tiap 10 detik
      _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
        await _sendLocation();
      });

    } catch (e) {
      debugPrint('❌ Error Start Tracking: $e');
      _isTracking = false;
      notifyListeners();
    }
  }

  // Pisahkan logika kirim lokasi agar bisa dipanggil langsung
  Future<void> _sendLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _apiService.updateLocation(
        _currentTripId!,
        pos.latitude,
        pos.longitude,
        pos.speed,
      );
      debugPrint('📍 Lokasi terkirim: ${pos.latitude}, ${pos.longitude}');
    } catch (e) {
      debugPrint('❌ Error kirim lokasi: $e');
    }
  }

  // ← Fix utama: endTrip dipanggil ke backend
  Future<void> _stopTracking() async {
    _timer?.cancel();
    _timer = null;

    if (_currentTripId != null) {
      try {
        await _apiService.endTrip(_currentTripId!);
        debugPrint('✅ Trip ${_currentTripId} selesai');
      } catch (e) {
        debugPrint('❌ Error End Trip: $e');
      }
    }

    _isTracking = false;
    _currentTripId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}