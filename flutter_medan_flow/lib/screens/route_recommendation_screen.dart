import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_medan_flow/services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────
// Palette (Profesional Medan Flow)
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
}

class RouteRecommendationScreen extends StatefulWidget {
  const RouteRecommendationScreen({super.key});

  @override
  State<RouteRecommendationScreen> createState() =>
      _RouteRecommendationScreenState();
}

class _RouteRecommendationScreenState
    extends State<RouteRecommendationScreen> {
  // ── Google Maps ────────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _mapController = Completer();

  // Polyline untuk rute (Google Maps pakai Set<Polyline>)
  Set<Polyline> _polylines = {};

  // Markers (titik asal user)
  Set<Marker> _markers = {};

  // ── State ──────────────────────────────────────────────────────────────────
  List _recommendations = [];
  bool _isLoading = false;
  int? _selectedRouteIndex;
  Timer? _debounce;

  final TextEditingController _originController = TextEditingController(
    text: "Mendeteksi lokasi...",
  );
  final TextEditingController _destController = TextEditingController();
  final FocusNode _destFocusNode = FocusNode();

  // ── Google Places Autocomplete ─────────────────────────────────────────────
  // Suggestion dari Google Places (nama, lat, lng)
  List<Map<String, dynamic>> _placeSuggestions = [];
  bool _showSuggestions = false;

  // Koordinat tujuan yang dipilih dari suggestion
  double? _destLat;
  double? _destLng;

  // API Key Google (ambil dari ApiService atau langsung)
  // Pastikan sama dengan key di AndroidManifest.xml
  static const _googleApiKey = ApiService.googleMapsKey; // ← sesuaikan dengan konstanta di ApiService Anda

  // ── GPS ────────────────────────────────────────────────────────────────────
  Position? _userPosition;

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
    _debounce?.cancel();
    _originController.dispose();
    _destController.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }

  // ── Deteksi Posisi User ────────────────────────────────────────────────────
  Future<void> _determinePosition() async {
    setState(() => _originController.text = "Mendeteksi GPS...");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _userPosition = position;
        _originController.text = "Lokasi Saya Saat Ini";
        // Tambah marker biru untuk posisi user
        _markers = {
          Marker(
            markerId: const MarkerId('user_location'),
            position: userLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Posisi Saya'),
          ),
        };
      });

      // Pindah kamera ke posisi user
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 14));
    } else {
      if (mounted) setState(() => _originController.text = "Izin GPS Ditolak");
    }
  }

  // ── Google Places Autocomplete ─────────────────────────────────────────────
  Future<void> _searchGooglePlaces(String query) async {
    if (query.length < 2) return;

    // Bias pencarian ke area Medan
    const location = '3.5952,98.6722';
    const radius = '50000'; // 50 km dari pusat Medan

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
    ).replace(queryParameters: {
      'input': query,
      'location': location,
      'radius': radius,
      'language': 'id',
      'components': 'country:id',
      'key': _googleApiKey,
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final predictions = data['predictions'] as List;

        setState(() {
          _placeSuggestions = predictions
              .map((p) => {
                    'description': p['description'] as String,
                    'place_id': p['place_id'] as String,
                  })
              .toList();
          _showSuggestions = _placeSuggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Places Autocomplete error: $e');
    }
  }

  // Ambil detail koordinat dari place_id
  Future<void> _getPlaceDetail(String placeId, String description) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json',
    ).replace(queryParameters: {
      'place_id': placeId,
      'fields': 'geometry',
      'key': _googleApiKey,
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final loc = data['result']['geometry']['location'];
        setState(() {
          _destLat = (loc['lat'] as num).toDouble();
          _destLng = (loc['lng'] as num).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Place Detail error: $e');
    }
  }

  void _onDestChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _showSuggestions = false;
        _destLat = null;
        _destLng = null;
      });
      return;
    }
    // Debounce 500ms
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchGooglePlaces(value);
    });
  }

  Future<void> _selectDestination(Map<String, dynamic> place) async {
    _destController.text = place['description'];
    _destFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
      _placeSuggestions = [];
    });
    // Ambil koordinat tujuan
    await _getPlaceDetail(place['place_id'], place['description']);
  }

  // ── Fetch Rute dari Laravel + Google Directions ────────────────────────────
  Future<void> _fetchSmartRoutes() async {
    final dest = _destController.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih tujuan dulu")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _polylines = {};
      _selectedRouteIndex = null;
    });

    try {
      // Step 1: Panggil Laravel untuk rekomendasi angkot
      final queryParams = <String, String>{'dest': dest};
      if (_userPosition != null) {
        queryParams['lat'] = _userPosition!.latitude.toString();
        queryParams['lng'] = _userPosition!.longitude.toString();
      }
      if (_destLat != null && _destLng != null) {
        queryParams['dest_lat'] = _destLat.toString();
        queryParams['dest_lng'] = _destLng.toString();
      }

      final uri = Uri.parse(
        "${ApiService().baseUrl}/recommendations",
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        // Step 2: Ambil rute dari Google Directions API (ganti Mapbox)
        if (_userPosition != null && data.isNotEmpty && _destLat != null && _destLng != null) {
          final geometry = await _fetchGoogleDirectionsGeometry(
            _userPosition!.latitude,
            _userPosition!.longitude,
            _destLat!,
            _destLng!,
          );

          for (var item in data) {
            item['geometry'] = geometry;
          }
        }

        setState(() {
          _recommendations = data;
          _selectedRouteIndex = data.isNotEmpty ? 0 : null;
        });

        if (_recommendations.isNotEmpty) {
          _drawRoute(_recommendations[0]['geometry'], index: 0);
        }
      } else {
        debugPrint("Laravel error: ${response.statusCode}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal mengambil data rute")),
          );
        }
      }
    } catch (e) {
      debugPrint("Analysis Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan koneksi")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google Directions API (ganti Mapbox Directions) ────────────────────────
  // Return: List of LatLng untuk polyline
  Future<List<LatLng>> _fetchGoogleDirectionsGeometry(
    double oLat, double oLng,
    double dLat, double dLng,
  ) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json',
      ).replace(queryParameters: {
        'origin': '$oLat,$oLng',
        'destination': '$dLat,$dLng',
        'mode': 'driving',
        'departure_time': 'now',       // traffic real-time
        'traffic_model': 'best_guess',
        'language': 'id',
        'key': _googleApiKey,
      });

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK') {
          // Google encode polyline pakai encoded polyline format
          final encodedPolyline =
              data['routes'][0]['overview_polyline']['points'] as String;
          return _decodePolyline(encodedPolyline);
        }
      }
    } catch (e) {
      debugPrint('Google Directions error: $e');
    }
    return [];
  }

  // Decode Google encoded polyline → List<LatLng>
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

  // ── Draw Route di Google Maps ──────────────────────────────────────────────
  Future<void> _drawRoute(dynamic geometry, {int? index}) async {
    List<LatLng> points = [];

    if (geometry is List<LatLng>) {
      points = geometry;
    } else if (geometry is List) {
      // Format lama (dari Mapbox: [[lng, lat], ...]) — fallback
      points = geometry
          .map<LatLng>((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
    }

    if (points.isEmpty) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('main_route'),
          points: points,
          color: _P.b600,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };
      if (index != null) _selectedRouteIndex = index;
    });

    // Pindah kamera ke tengah rute
    if (points.isNotEmpty) {
      final mid = points[points.length ~/ 2];
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(mid, 12));
    }
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
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: _P.b600),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Navigasi Pintar',
          style: TextStyle(fontWeight: FontWeight.w900, color: _P.ink, fontSize: 18),
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
            // 1. GOOGLE MAP ──────────────────────────────────────────────────
            GoogleMap(
              onMapCreated: (controller) => _mapController.complete(controller),
              initialCameraPosition: const CameraPosition(
                target: LatLng(3.5952, 98.6722),
                zoom: 13,
              ),
              markers: _markers,
              polylines: _polylines,
              trafficEnabled: true,          // ← ganti Mapbox traffic-day tile
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),

            // 2. SEARCH PANEL ────────────────────────────────────────────────
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
                    _buildReadOnlyInput(
                      Icons.my_location_rounded,
                      _originController,
                      _P.b600,
                    ),
                    const Divider(height: 24),
                    _buildDestInput(),
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
                            ? const CircularProgressIndicator(color: Colors.white)
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

            // 3. ZOOM CONTROLS ───────────────────────────────────────────────
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.42,
              child: Column(
                children: [
                  _buildMapActionBtn(
                    Icons.add_rounded,
                    () async {
                      final c = await _mapController.future;
                      c.animateCamera(CameraUpdate.zoomIn());
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMapActionBtn(
                    Icons.remove_rounded,
                    () async {
                      final c = await _mapController.future;
                      c.animateCamera(CameraUpdate.zoomOut());
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMapActionBtn(
                    Icons.my_location_rounded,
                    _determinePosition,
                    accent: true,
                  ),
                ],
              ),
            ),

            // 4. DRAGGABLE RESULTS ────────────────────────────────────────────
            _buildDraggableResults(),
          ],
        ),
      ),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────────────────────

  Widget _buildReadOnlyInput(IconData icon, TextEditingController ctrl, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: ctrl,
            readOnly: true,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              isDense: true, border: InputBorder.none, hintText: "Asal",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestInput() {
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
                  fontSize: 14, fontWeight: FontWeight.bold, color: _P.ink,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: "Ketik tujuan...",
                ),
              ),
            ),
            // Tombol clear
            if (_destController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _destController.clear();
                  setState(() {
                    _placeSuggestions = [];
                    _showSuggestions = false;
                    _destLat = null;
                    _destLng = null;
                  });
                  _destFocusNode.requestFocus();
                },
                child: const Icon(Icons.close, size: 18, color: _P.ink4),
              ),
          ],
        ),

        // Dropdown suggestion dari Google Places
        if (_showSuggestions && _placeSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: _P.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _P.b100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _placeSuggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final place = _placeSuggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, color: _P.b400, size: 18),
                  title: Text(
                    place['description'],
                    style: const TextStyle(fontSize: 13, color: _P.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectDestination(place),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMapActionBtn(IconData icon, VoidCallback onTap, {bool accent = false}) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: accent ? _P.b600 : _P.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: accent ? Colors.white : _P.b600, size: 20),
        onPressed: onTap,
      ),
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
              BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: _P.b100, borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'OPSI RUTE TERBAIK',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _P.ink2),
                ),
              ),
              Expanded(
                child: _recommendations.isEmpty
                    ? SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: [
                              Icon(Icons.route_outlined, size: 48, color: _P.b200),
                              const SizedBox(height: 12),
                              const Text(
                                "Masukkan tujuan dan klik\nANALISIS JALUR TERCEPAT",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _P.ink3, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
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
          boxShadow: [
            BoxShadow(
              color: _P.b500.withOpacity(isSelected ? 0.12 : 0.05),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [_P.b500, _P.b700])
                    : const LinearGradient(colors: [_P.b50, _P.b100]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildEtaBadge(item['eta']?.toString() ?? '0 menit', isSelected),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Rute Angkot',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    item['distance'] ?? '',
                    style: const TextStyle(fontSize: 12, color: _P.ink3),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.directions_rounded,
              color: isSelected ? _P.b600 : _P.b400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtaBadge(String etaStr, bool isSelected) {
    final menit = int.tryParse(etaStr.split(" ")[0]) ?? 0;
    final color = isSelected ? Colors.white : _P.b600;
    final subColor = isSelected ? Colors.white70 : _P.ink4;

    if (menit < 60) {
      return Column(
        children: [
          Text('$menit',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text('MENIT',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: subColor)),
        ],
      );
    }

    final jam  = menit ~/ 60;
    final sisa = menit % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$jam',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(width: 2),
            Text('Jam',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subColor)),
          ],
        ),
        if (sisa > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$sisa',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(width: 2),
              Text('Min',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subColor)),
            ],
          ),
      ],
    );
  }
}