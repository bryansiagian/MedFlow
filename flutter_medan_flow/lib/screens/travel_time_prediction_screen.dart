import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────
// Palette (sama persis dengan LandingPage)
// ─────────────────────────────────────────────
class _P {
  static const b50  = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b200 = Color(0xFFBFDBFE);
  static const b300 = Color(0xFF93C5FD);
  static const b400 = Color(0xFF60A5FA);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b700 = Color(0xFF1D4ED8);
  static const b800 = Color(0xFF1E40AF);
  static const bg   = Color(0xFFEEF4FF);
  static const card = Colors.white;
  static const ink  = Color(0xFF0F172A);
  static const ink2 = Color(0xFF334155);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
  static const dark = Color(0xFF0F2878);
}

class TravelTimePredictionScreen extends StatefulWidget {
  const TravelTimePredictionScreen({super.key});

  @override
  State<TravelTimePredictionScreen> createState() =>
      _TravelTimePredictionScreenState();
}

class _TravelTimePredictionScreenState
    extends State<TravelTimePredictionScreen> {
  // ── Google Maps ────────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _mapController = Completer();
  static const LatLng _medanCenter = LatLng(3.5952, 98.6722);

  // Kamera center saat user geser peta (untuk pin selector)
  LatLng _currentMapCenter = _medanCenter;

  // Polyline rute
  Set<Polyline> _polylines = {};

  // Markers (asal + tujuan)
  Set<Marker> _markers = {};

  // ── State ──────────────────────────────────────────────────────────────────
  int _step = 0;
  bool _isLoading = false;
  bool _isLocating = true;

  LatLng? _originPoint;
  LatLng? _destPoint;
  Position? _userPosition;
  Map<String, dynamic>? _predictionData;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // ── Deteksi GPS → set asal otomatis ───────────────────────────────────────
  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _userPosition = position;
          _currentMapCenter = userLatLng;
          _originPoint = userLatLng; // Asal otomatis dari GPS
          _step = 1;                 // Langsung ke step pilih tujuan
        });

        _updateMarkers();

        final controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15.0));
      }
    }

    if (mounted) setState(() => _isLocating = false);
  }

  // ── Update markers sesuai state ────────────────────────────────────────────
  void _updateMarkers() {
    final newMarkers = <Marker>{};

    if (_originPoint != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('origin'),
        position: _originPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Titik Asal'),
      ));
    }

    if (_destPoint != null && _step == 2) {
      newMarkers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Titik Tujuan'),
      ));
    }

    setState(() => _markers = newMarkers);
  }

  // ── Hitung Rute via API ────────────────────────────────────────────────────
  Future<void> _calculateRoute() async {
    if (_originPoint == null || _destPoint == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService().getTravelPrediction(
        _originPoint!.latitude,
        _originPoint!.longitude,
        _destPoint!.latitude,
        _destPoint!.longitude,
      );

      if (response != null) {
        List<LatLng> points = [];

        // PredictionController sekarang return encoded polyline string
        // decode dulu sebelum dipakai
        if (response['route_geometry'] != null) {
          final geometry = response['route_geometry'];
          if (geometry is String && geometry.isNotEmpty) {
            // Encoded polyline dari Google Directions API
            points = _decodePolyline(geometry);
          } else if (geometry is List && geometry.isNotEmpty) {
            // Format lama (array koordinat) — fallback
            points = (geometry as List)
                .map((p) => LatLng(
                      (p[1] as num).toDouble(),
                      (p[0] as num).toDouble(),
                    ))
                .toList();
          }
        }

        if (points.isEmpty) {
          points = [_originPoint!, _destPoint!];
        }

        setState(() {
          _predictionData = response;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: _P.b500,
              width: 5,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          };
          _step = 2;
        });

        _updateMarkers();

        // Pindah kamera ke tengah rute
        final midLat = (_originPoint!.latitude + _destPoint!.latitude) / 2;
        final midLng = (_originPoint!.longitude + _destPoint!.longitude) / 2;
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(midLat, midLng), 13.5),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menganalisis rute. Cek koneksi ke server."),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Decode Google encoded polyline → List<LatLng> ──────────────────────────
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // ── Reset Screen ───────────────────────────────────────────────────────────
  Future<void> _resetScreen() async {
    final userLatLng = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : _medanCenter;

    setState(() {
      _step = _userPosition != null ? 1 : 0;
      _originPoint = _userPosition != null ? userLatLng : null;
      _destPoint = null;
      _predictionData = null;
      _polylines = {};
      _currentMapCenter = userLatLng;
    });

    _updateMarkers();

    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15.0));
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: _P.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _P.b100, width: 1.5),
              boxShadow: [
                BoxShadow(color: _P.b500.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: _P.b600),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: _step < 2
            ? null
            : ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [_P.b600, Color(0xFF06B6D4)],
                ).createShader(b),
                child: const Text(
                  'Hasil Analisis',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: -0.3,
                  ),
                ),
              ),
      ),
      body: Stack(
        children: [
          // 1. GOOGLE MAP ─────────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            initialCameraPosition: const CameraPosition(
              target: _medanCenter,
              zoom: 15,
            ),
            // Panggil ini saat user menggeser peta (untuk pin selector)
            onCameraMove: (position) {
              if (_step < 2) {
                _currentMapCenter = position.target;
              }
            },
            markers: _markers,
            polylines: _polylines,
            trafficEnabled: true,           // ganti Mapbox traffic style
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // 2. LOADING GPS OVERLAY ────────────────────────────────────────────
          if (_isLocating)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: _P.card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _P.b600.withOpacity(0.15), blurRadius: 20)],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _P.b600, strokeWidth: 3),
                      SizedBox(height: 14),
                      Text(
                        'Mendeteksi lokasi Anda...',
                        style: TextStyle(fontWeight: FontWeight.w700, color: _P.ink, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. PIN SELECTOR (tengah layar) ────────────────────────────────────
          // Hanya tampil saat step < 2 dan GPS sudah selesai
          if (_step < 2 && !_isLocating)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _P.ink.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _P.b800.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Text(
                        _step == 0 ? "Titik Keberangkatan" : "Titik Tujuan Perjalanan",
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w800, letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_step == 0 ? _P.b600 : const Color(0xFFEA580C)).withOpacity(0.40),
                            blurRadius: 16, offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: _step == 0 ? _P.b500 : const Color(0xFFEA580C),
                        size: 52,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. INFO CARD TOP ───────────────────────────────────────────────────
          if (_step < 2 && !_isLocating)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _P.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _P.b100, width: 1.5),
                  boxShadow: [BoxShadow(color: _P.b500.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _step == 0
                              ? [_P.b50, _P.b100]
                              : [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _step == 0 ? Icons.my_location_rounded : Icons.flag_rounded,
                        color: _step == 0 ? _P.b600 : const Color(0xFFEA580C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _step == 0 ? "Tentukan Lokasi Asal" : "Tentukan Lokasi Tujuan",
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _P.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _step == 1 && _userPosition != null
                                ? "Asal otomatis dari GPS Anda"
                                : "Geser peta untuk memposisikan pin",
                            style: const TextStyle(color: _P.ink3, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _P.b50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _P.b100, width: 1),
                      ),
                      child: Text(
                        '${_step + 1}/2',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _P.b600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. ACTION BUTTON ───────────────────────────────────────────────────
          if (_step < 2 && !_isLocating)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    if (_step == 0) {
                      setState(() {
                        _originPoint = _currentMapCenter;
                        _step = 1;
                      });
                      _updateMarkers();
                    } else if (_step == 1) {
                      setState(() => _destPoint = _currentMapCenter);
                      _calculateRoute();
                    }
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_P.b500, _P.b700],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: _P.b600.withOpacity(0.40), blurRadius: 18, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              _step == 0 ? "KONFIRMASI ASAL" : "ANALISIS ESTIMASI WAKTU",
                              style: const TextStyle(
                                color: Colors.white, fontSize: 13.5,
                                fontWeight: FontWeight.w900, letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

          // 6. KARTU HASIL ────────────────────────────────────────────────────
          if (_step == 2 && _predictionData != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: _P.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Color(0x1A2563EB), blurRadius: 32, offset: Offset(0, -6))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: _P.b100, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_P.b600, _P.b800, _P.dark],
                          stops: [0.0, 0.55, 1.0],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: _P.b600.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESTIMASI PERJALANAN',
                                style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _predictionData!['predicted_time'],
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.20)),
                            ),
                            child: Text(
                              _predictionData!['congestion_level'].toString().toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(_predictionData!['status_color']),
                                fontSize: 10, fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Row(
                        children: [
                          _buildStatCard(
                            Icons.route_outlined, "Jarak",
                            _predictionData!['distance'],
                            [_P.b50, _P.b100], _P.b500,
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            Icons.cloud_queue_rounded, "Cuaca",
                            _predictionData!['prediction_factors']['weather'],
                            [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
                            const Color(0xFF0EA5E9),
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            Icons.timer_outlined, "Delay",
                            _predictionData!['delay'],
                            [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)],
                            const Color(0xFFEA580C),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _P.b600,
                            side: const BorderSide(color: _P.b200, width: 1.5),
                            backgroundColor: _P.b50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _resetScreen,
                          icon: const Icon(Icons.refresh_rounded, size: 18, color: _P.b600),
                          label: const Text(
                            "CARI RUTE LAIN",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _P.b600, letterSpacing: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── WIDGET HELPERS ─────────────────────────────────────────────────────────

  Widget _buildStatCard(IconData icon, String label, String value, List<Color> bgColors, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [BoxShadow(color: _P.b500.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: bgColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: _P.ink3, fontSize: 10, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(value, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _P.ink, height: 1.2)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'red':    return const Color(0xFFDC2626);
      case 'orange': return const Color(0xFFEA580C);
      case 'blue':   return const Color(0xFF2563EB);
      default:       return const Color(0xFF16A34A);
    }
  }
}