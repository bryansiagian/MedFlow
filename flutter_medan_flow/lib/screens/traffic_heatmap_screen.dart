import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette (Konsisten dengan Tema Medan Flow)
// ─────────────────────────────────────────────
class _P {
  static const b50 = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b300 = Color(0xFF93C5FD);
  static const b400 = Color(0xFF60A5FA);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b700 = Color(0xFF1D4ED8);
  static const b800 = Color(0xFF1E40AF);
  static const bg = Color(0xFFEEF4FF);
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color.fromARGB(255, 120, 147, 185);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
  static const dark = Color(0xFF0F2878);
}

class TrafficHeatmapScreen extends StatefulWidget {
  const TrafficHeatmapScreen({super.key});

  @override
  State<TrafficHeatmapScreen> createState() => _TrafficHeatmapScreenState();
}

class _TrafficHeatmapScreenState extends State<TrafficHeatmapScreen> {
  final MapController _mapController = MapController();
  double _predictionMinutes = 5.0;

  // Data State
  List<Polyline> _aiPolylines = [];
  bool _isLoading = false;
  String _aiPrediction = '';
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // ── Fungsi Mendeteksi Lokasi GPS Asli ────────────────────────
  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userPosition = position;
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            14,
          );
        });
      }
    }
    _fetchHeatmapData();
  }

  // ── Ambil Data Hybrid dari Backend ──────────────────────────
  Future<void> _fetchHeatmapData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String url =
          "${ApiService().baseUrl}/traffic-heatmap?minutes=${_predictionMinutes.toInt()}";
      if (_userPosition != null) {
        url +=
            "&lat=${_userPosition!.latitude}&lng=${_userPosition!.longitude}";
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body['data'] ?? [];

        if (mounted) {
          setState(() {
            _aiPrediction = body['ai_prediction'] ?? '';
            _generateAiPolylines(data);
          });
        }
      }
    } catch (e) {
      debugPrint("Heatmap Logic Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateAiPolylines(List data) {
    List<Polyline> newPolylines = [];

    for (var item in data) {
      if (item['geometry'] == null || (item['geometry'] as List).isEmpty)
        continue;

      List<LatLng> points = (item['geometry'] as List).map((coord) {
        return LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }).toList();

      Color roadColor;
      switch (item['congestion_level']) {
        case 'sangat_macet':
          roadColor = const Color(0xFF7B0000);
          break;
        case 'macet':
          roadColor = Colors.red;
          break;
        case 'padat':
          roadColor = Colors.orange;
          break;
        default:
          roadColor = Colors.green;
      }

      newPolylines.add(
        Polyline(
          points: points,
          color: roadColor.withOpacity(0.85),
          strokeWidth: 6.5, // Dipertebal agar lebih mempesona
          borderColor: Colors.white.withOpacity(0.4),
          borderStrokeWidth: 1.5,
        ),
      );
    }
    setState(() {
      _aiPolylines = newPolylines;
    });
  }

  void _zoomIn() => _mapController.move(
    _mapController.camera.center,
    _mapController.camera.zoom + 1,
  );
  void _zoomOut() => _mapController.move(
    _mapController.camera.center,
    _mapController.camera.zoom - 1,
  );

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    bool isPredicting = _predictionMinutes > 5;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── 1. PETA DINAMIS (TETAP BERWARNA) ────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(3.5952, 98.6722),
              initialZoom: 14,
            ),
            children: [
              // MENGGUNAKAN STYLE STREETS AGAR TIDAK ABU-ABU
              TileLayer(
                urlTemplate: isPredicting
                    ? 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${ApiService.mapboxToken}'
                    : 'https://api.mapbox.com/styles/v1/${ApiService.mapboxTrafficStyle}/tiles/256/{z}/{x}/{y}@2x?access_token=${ApiService.mapboxToken}',
                additionalOptions: const {
                  'accessToken': ApiService.mapboxToken,
                },
                userAgentPackageName: 'com.medanflow.app',
              ),

              // Garis Jalan AI
              if (isPredicting) PolylineLayer(polylines: _aiPolylines),
            ],
          ),

          // ── 2. Header (Floating glass) ───────────────────────
          Positioned(
            top: topPad + 12,
            left: 20,
            right: 20,
            child: _buildHeader(isPredicting),
          ),

          // ── 3. Legend ────────────────────────────────────────
          Positioned(top: topPad + 85, left: 20, child: _buildLegend()),

          // ── 4. Zoom Controls ──────────────────────────────────
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.38,
            child: _buildZoomControls(),
          ),

          // ── 5. Prediction Panel ───────────────────────────────
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildPredictionPanel(),
          ),

          // ── 6. Loading Indicator ──────────────────────────────
          if (_isLoading)
            Positioned(
              top: topPad + 80,
              left: 0,
              right: 0,
              child: Center(child: _buildLoadingChip()),
            ),
        ],
      ),
    );
  }

  // ── Widget Helper UI ─────────────────────────────────────────

  Widget _buildHeader(bool isPredicting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _P.b50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.b100, width: 1.5),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _P.b600,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [_P.b600, Color(0xFF06B6D4)],
                  ).createShader(b),
                  child: const Text(
                    'Prediksi Kemacetan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Text(
                  isPredicting
                      ? 'Visualisasi Kecerdasan Buatan'
                      : 'Heatmap real-time Kota Medan',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _P.ink3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchHeatmapData,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_P.b500, _P.b700]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _P.b600.withOpacity(0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.b100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INFORMASI',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: _P.ink4,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 7),
          _legendItem(const Color(0xFF7B0000), 'Sangat Macet'),
          const SizedBox(height: 5),
          _legendItem(Colors.red, 'Macet Parah'),
          const SizedBox(height: 5),
          _legendItem(Colors.orange, 'Padat Merayap'),
          const SizedBox(height: 5),
          _legendItem(Colors.green, 'Lancar'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _P.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Column(
      children: [
        _zoomBtn(Icons.add_rounded, _zoomIn),
        const SizedBox(height: 8),
        _zoomBtn(Icons.remove_rounded, _zoomOut),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _P.b500.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: _P.b600, size: 20),
      ),
    );
  }

  Widget _buildLoadingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_P.b600, _P.b800]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _P.b600.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 9),
          Text(
            'AI Menganalisis...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _P.b500.withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _P.b50,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _P.b100, width: 1.5),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: _P.b600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analisis Masa Depan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _P.ink,
                      ),
                    ),
                    Text(
                      'Berdasarkan Google Gemini 2.0 Flash',
                      style: TextStyle(
                        fontSize: 10,
                        color: _P.ink3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_P.b500, _P.b700]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '+${_predictionMinutes.toInt()} Mnt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Slider(
            value: _predictionMinutes,
            min: 5,
            max: 30,
            divisions: 5,
            activeColor: _P.b600,
            onChanged: (v) => setState(() => _predictionMinutes = v),
            onChangeEnd: (_) => _fetchHeatmapData(),
          ),
          if (_aiPrediction.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: _P.b100),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _aiPrediction,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _P.ink,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
