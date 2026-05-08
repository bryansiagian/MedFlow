import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette & Styling (Konsisten dengan Tema Profesional Medan Flow)
// ─────────────────────────────────────────────────────────────────────────────
class _P {
  static const b50  = Color(0xFFEFF6FF);
  static const b100 = Color(0xFFDBEAFE);
  static const b300 = Color(0xFF93C5FD);
  static const b500 = Color(0xFF3B82F6);
  static const b600 = Color(0xFF2563EB);
  static const b800 = Color(0xFF1E40AF);
  static const ink  = Color(0xFF0F172A);
  static const ink2 = Color(0xFF334155);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);
  static const dark = Color(0xFF0F2878);
}

class AngkotTrackingScreen extends StatefulWidget {
  const AngkotTrackingScreen({super.key});

  @override
  State<AngkotTrackingScreen> createState() => _AngkotTrackingScreenState();
}

class _AngkotTrackingScreenState extends State<AngkotTrackingScreen>
    with SingleTickerProviderStateMixin {
  // ── Kontroler & Data ───────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  final Completer<GoogleMapController> _mapController = Completer();

  // Google Maps pakai Set<Marker>, bukan List<Marker>
  Set<Marker> _markers = {};
  Timer? _timer;
  bool _isLoading = true;
  List<dynamic> _angkotList = [];
  LatLng _cameraCenter = const LatLng(3.5952, 98.6722); // Default Medan

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initTracking();
  }

  Future<void> _initTracking() async {
    await _determineUserPosition();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 10), (t) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _orbCtrl.dispose();
    super.dispose();
  }

  // ── Deteksi Lokasi User ────────────────────────────────────────────────────
  Future<void> _determineUserPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    final newCenter = LatLng(position.latitude, position.longitude);
    setState(() => _cameraCenter = newCenter);

    // Move camera ke lokasi user
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(newCenter, 14.0));
  }

  // ── Ambil Data Angkot dari API ─────────────────────────────────────────────
  Future<void> _fetchData() async {
    try {
      final data = await _apiService.getActiveAngkots();
      if (!mounted) return;
      setState(() {
        _angkotList = data;
        _markers = _buildMarkers(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Tracking Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build Markers untuk Google Maps ───────────────────────────────────────
  Set<Marker> _buildMarkers(List<dynamic> data) {
    final newMarkers = <Marker>{};
    for (final angkot in data) {
      final isFull = angkot['crowd_status'] == 'Penuh';
      newMarkers.add(
        Marker(
          markerId: MarkerId(angkot['angkot_number'].toString()),
          position: LatLng(
            double.parse(angkot['latitude'].toString()),
            double.parse(angkot['longitude'].toString()),
          ),
          // Google Maps built-in hue: merah jika penuh, biru jika tidak
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isFull ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: 'Angkot ${angkot['angkot_number']}',
            snippet:
                '${angkot['crowd_status']} · ${angkot['eta_minutes']} menit · ${angkot['route_name'] ?? 'Rute Medan'}',
          ),
          onTap: () => _focusOnAngkot(angkot),
        ),
      );
    }
    return newMarkers;
  }

  // ── Navigasi Kamera ────────────────────────────────────────────────────────
  Future<void> _focusOnAngkot(dynamic angkot) async {
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(
          double.parse(angkot['latitude'].toString()),
          double.parse(angkot['longitude'].toString()),
        ),
        15.0,
      ),
    );
  }

  Future<void> _zoomIn() async {
    final c = await _mapController.future;
    c.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final c = await _mapController.future;
    c.animateCamera(CameraUpdate.zoomOut());
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. GOOGLE MAP ─────────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (controller) => _mapController.complete(controller),
            initialCameraPosition: CameraPosition(
              target: _cameraCenter,
              zoom: 13,
            ),
            markers: _markers,
            trafficEnabled: true,        // ← Ganti Mapbox traffic tile layer
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // kita buat tombol sendiri
            zoomControlsEnabled: false,     // kita buat tombol sendiri
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // 2. ZOOM & MY LOCATION CONTROLS ────────────────────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                _buildMapActionBtn(Icons.add_rounded, _zoomIn),
                const SizedBox(height: 8),
                _buildMapActionBtn(Icons.remove_rounded, _zoomOut),
                const SizedBox(height: 8),
                _buildMapActionBtn(
                  Icons.my_location_rounded,
                  _determineUserPosition,
                  accent: true,
                ),
              ],
            ),
          ),

          // 3. DRAGGABLE LIST PANEL ───────────────────────────────────────────
          _buildDraggableAngkotList(),

          // 4. HEADER OVERLAY ────────────────────────────────────────────────
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

          // 5. LOADING OVERLAY ────────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: _P.b600, strokeWidth: 3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_P.b600, _P.b800, _P.dark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: _P.b600.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Material(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Tracking Angkot',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'GPS Aktif - Lokasi Real-time',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _buildLiveBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionBtn(IconData icon, VoidCallback onTap, {bool accent = false}) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: accent ? _P.b600 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [
          BoxShadow(color: _P.b500.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: accent ? Colors.white : _P.b600, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildDraggableAngkotList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.10,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Color(0x1A1D4ED8), blurRadius: 24, offset: Offset(0, -6))],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 40, height: 4,
                decoration: BoxDecoration(color: _P.b100, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ARMADA AKTIF',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _P.ink, letterSpacing: 0.8),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _P.b50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _P.b100),
                      ),
                      child: Text(
                        '${_angkotList.length} Unit',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _P.b600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: _angkotList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
                        itemCount: _angkotList.length,
                        itemBuilder: (context, index) => _buildAngkotCard(_angkotList[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAngkotCard(dynamic angkot) {
    final isFull = angkot['crowd_status'] == 'Penuh';
    final accentColor = isFull ? const Color(0xFFDC2626) : _P.b600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _P.b100, width: 1.5),
        boxShadow: [BoxShadow(color: _P.b500.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _focusOnAngkot(angkot),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: isFull ? const Color(0xFFFEF2F2) : _P.b50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.directions_bus_filled_rounded, color: accentColor, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Angkot ${angkot['angkot_number']}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _P.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      angkot['route_name'] ?? 'Rute Medan',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _P.ink3, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusBadge(angkot['crowd_status']),
                        const SizedBox(width: 10),
                        const Icon(Icons.timer_outlined, size: 14, color: _P.ink4),
                        const SizedBox(width: 4),
                        Text(
                          '${angkot['eta_minutes']} Menit',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _P.ink2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _P.ink4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isFull = status == 'Penuh';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFull ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFull ? const Color(0xFFFECACA) : const Color(0xFF86EFAC),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isFull ? const Color(0xFFDC2626) : const Color(0xFF15803D),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: _P.b50, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.bus_alert_rounded, size: 36, color: _P.b300),
          ),
          const SizedBox(height: 15),
          const Text(
            'Tidak Ada Armada Aktif',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _P.ink2),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan tombol GPS untuk memusatkan peta ke lokasi Anda.',
            style: TextStyle(fontSize: 12, color: _P.ink4, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}