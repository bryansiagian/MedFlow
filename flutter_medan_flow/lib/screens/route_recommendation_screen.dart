import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
// Palette (Profesional Medan Flow)
// ─────────────────────────────────────────────
class _P {
  static const b50 = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b200 = Color(0xFFBFDBFE);
  static const b300 = Color(0xFF93C5FD);
  static const b400 = Color(0xFF60A5FA);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b700 = Color(0xFF1D4ED8);
  static const b800 = Color(0xFF1E40AF);
  static const bg = Color(0xFFEEF4FF);
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF334155);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
}

class RouteRecommendationScreen extends StatefulWidget {
  const RouteRecommendationScreen({super.key});

  @override
  State<RouteRecommendationScreen> createState() =>
      _RouteRecommendationScreenState();
}

class _RouteRecommendationScreenState extends State<RouteRecommendationScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  List _recommendations = [];
  bool _isLoading = false;

  final TextEditingController _originController = TextEditingController(
    text: "Mendeteksi lokasi...",
  );
  final TextEditingController _destController = TextEditingController();
  final FocusNode _destFocusNode = FocusNode();

  final List<String> _popularDestinations = [
    "Pinang Baris",
    "Amplas",
    "Lapangan Merdeka",
    "Sunggal",
    "Helvetia",
    "Padang Bulan",
    "Kampung Lalang",
    "Marelan",
    "Belawan",
    "Binjai",
    "Polonia",
    "Aksara",
    "Pancing",
    "Pasar Petisah",
    "Tembung",
    "Delitua",
    "Sei Sikambing",
    "Pusat Pasar Medan",
    "Petisah",
    "Medan Kota",
  ];

  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;

  Position? _userPosition;
  List<LatLng> _currentPolyline = [];
  int? _selectedRouteIndex;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _destFocusNode.addListener(() {
      if (!_destFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => _originController.text = "Mendeteksi GPS...");
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userPosition = position;
          _originController.text = "Lokasi Saya Saat Ini";
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            14,
          );
        });
      }
    }
  }

  void _onDestChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final filtered = _popularDestinations
        .where((d) => d.toLowerCase().contains(value.toLowerCase()))
        .take(6)
        .toList();
    setState(() {
      _filteredSuggestions = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  void _selectDestination(String place) {
    _destController.text = place;
    _destFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
      _filteredSuggestions = [];
    });
  }

  void _clearDest() {
    _destController.clear();
    setState(() {
      _showSuggestions = false;
      _filteredSuggestions = [];
    });
    _destFocusNode.requestFocus();
  }

  Future<void> _fetchSmartRoutes() async {
    final dest = _destController.text.trim();
    if (dest.isEmpty) {
      _showSnack("Masukkan tujuan terlebih dahulu.");
      return;
    }

    setState(() {
      _isLoading = true;
      _currentPolyline = [];
      _selectedRouteIndex = null;
    });

    try {
      // Pastikan baseUrl sudah benar (tidak pakai titik dua sebelum /api)
      String url = "${_apiService.baseUrl}/recommendations";
      final queryParams = <String, String>{'dest': dest};

      if (_userPosition != null) {
        queryParams['lat'] = _userPosition!.latitude.toString();
        queryParams['lng'] = _userPosition!.longitude.toString();
      }

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _recommendations = data;
            _selectedRouteIndex = data.isNotEmpty ? 0 : null;
          });
          if (_recommendations.isNotEmpty &&
              _recommendations[0]['geometry'] != null) {
            _drawRoute(_recommendations[0]['geometry'], index: 0);
          }
        }
      } else {
        _showSnack("Server bermasalah (Error ${response.statusCode})");
      }
    } catch (e) {
      _showSnack("Koneksi gagal. Periksa server Laravel Anda.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _drawRoute(dynamic geometry, {int? index}) {
    if (geometry == null || geometry is! List || geometry.isEmpty) return;
    List<LatLng> points = [];
    for (var coord in geometry) {
      points.add(
        LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()),
      );
    }
    setState(() {
      _currentPolyline = points;
      if (index != null) _selectedRouteIndex = index;
    });
    if (points.isNotEmpty) {
      _mapController.move(points[points.length ~/ 2], 13.0);
    }
  }

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
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: _P.b600,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Navigasi Pintar',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _P.ink,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _showSuggestions = false);
        },
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(3.5952, 98.6722),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/${ApiService.mapboxTrafficStyle}/tiles/256/{z}/{x}/{y}@2x?access_token=${ApiService.mapboxToken}',
                  userAgentPackageName: 'com.medanflow.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _currentPolyline,
                      color: _P.b600,
                      strokeWidth: 5.5,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
                if (_userPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                        ),
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _P.b600,
                            boxShadow: [
                              BoxShadow(
                                color: _P.b600.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 66,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _P.card,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: _P.b500.withOpacity(0.1), blurRadius: 16),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchInput(
                      Icons.my_location_rounded,
                      "Asal",
                      _originController,
                      _P.b600,
                    ),
                    const Divider(height: 24),
                    _buildEditableDestInput(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fetchSmartRoutes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _P.b600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "ANALISIS JALUR TERCEPAT",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.42,
              child: Column(
                children: [
                  _buildMapActionBtn(
                    Icons.add_rounded,
                    () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMapActionBtn(
                    Icons.remove_rounded,
                    () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    ),
                  ),
                ],
              ),
            ),
            _buildDraggableResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableDestInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_rounded, size: 20, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _destController,
                focusNode: _destFocusNode,
                onChanged: _onDestChanged,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _P.ink,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: "Ketik tujuan...",
                ),
              ),
            ),
          ],
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: _P.card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: _filteredSuggestions
                  .map(
                    (s) => ListTile(
                      title: Text(s, style: const TextStyle(fontSize: 13)),
                      onTap: () => _selectDestination(s),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMapActionBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: IconButton(
        icon: Icon(icon, color: _P.b600),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSearchInput(
    IconData icon,
    String hint,
    TextEditingController ctrl,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: ctrl,
            readOnly: true,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableResults() {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _P.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _P.b100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'OPSI RUTE TERBAIK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _P.ink2,
                  ),
                ),
              ),
              Expanded(
                child: _recommendations.isEmpty
                    ? const Center(child: Text("Silakan cari rute di atas"))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _recommendations.length,
                        itemBuilder: (context, index) =>
                            _buildRouteCard(_recommendations[index], index),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> item, int index) {
    final isSelected = _selectedRouteIndex == index;
    return GestureDetector(
      onTap: () => _drawRoute(item['geometry'], index: index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _P.b50 : _P.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _P.b400 : _P.b100),
        ),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  item['eta']?.split(" ")[0] ?? "0",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _P.b600,
                  ),
                ),
                const Text(
                  'MENIT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _P.ink4,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? "Rute Medan",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    item['distance']?.toString() ?? "-",
                    style: const TextStyle(fontSize: 12, color: _P.ink3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.directions_rounded, color: _P.b400, size: 24),
          ],
        ),
      ),
    );
  }
}
