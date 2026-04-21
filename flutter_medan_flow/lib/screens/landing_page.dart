import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_medan_flow/services/api_service.dart';
import 'login_screen.dart';
import 'route_recommendation_screen.dart';
import 'traffic_heatmap_screen.dart';
import 'angkot_tracking_screen.dart';
import 'notification_screen.dart';
import 'onboarding_overlay.dart';
import '../config.dart';

// ─────────────────────────────────────────────
// Palette
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

// ══════════════════════════════════════════════════════════════
//  ANIMATED WEATHER ICONS (tidak diubah dari original)
// ══════════════════════════════════════════════════════════════

class RainyWeatherIcon extends StatefulWidget {
  final double size;
  const RainyWeatherIcon({super.key, this.size = 40});
  @override
  State<RainyWeatherIcon> createState() => _RainyWeatherIconState();
}

class _RainyWeatherIconState extends State<RainyWeatherIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(size: Size(widget.size, widget.size), painter: _RainyPainter(t: _ctrl.value)),
  );
}

class _RainyPainter extends CustomPainter {
  final double t;
  _RainyPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final floatY = math.sin(t * math.pi * 2) * 3.5;
    _drawCloud(canvas, w, h, floatY, Paint()..color = Colors.white.withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    _drawCloud(canvas, w, h, floatY, Paint()..shader = LinearGradient(colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.72)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.56)));
    final dropPositions = [Offset(w * 0.24, h * 0.62), Offset(w * 0.38, h * 0.65), Offset(w * 0.53, h * 0.62), Offset(w * 0.68, h * 0.65), Offset(w * 0.31, h * 0.76), Offset(w * 0.60, h * 0.76)];
    final delays = [0.0, 0.20, 0.40, 0.60, 0.10, 0.50];
    for (int i = 0; i < dropPositions.length; i++) {
      final progress = (t + delays[i]) % 1.0;
      final opacity = progress < 0.65 ? (progress < 0.1 ? progress / 0.1 : 1.0) : (1.0 - progress) / 0.35;
      final yOff = progress * h * 0.25;
      final p1 = dropPositions[i].translate(0, yOff + floatY);
      final p2 = p1.translate(-h * 0.05, h * 0.12);
      canvas.drawLine(p1, p2, Paint()..color = Colors.white.withOpacity((opacity * 0.88).clamp(0, 1))..strokeWidth = 2.4..strokeCap = StrokeCap.round);
    }
  }
  void _drawCloud(Canvas canvas, double w, double h, double floatY, Paint paint) {
    final cx = w * 0.50; final cy = h * 0.30 + floatY;
    final path = ui.Path();
    path.addOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.58, height: h * 0.32));
    path.addOval(Rect.fromCenter(center: Offset(cx - w * 0.19, cy + h * 0.05), width: w * 0.30, height: h * 0.24));
    path.addOval(Rect.fromCenter(center: Offset(cx + w * 0.19, cy + h * 0.06), width: w * 0.26, height: h * 0.20));
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - w * 0.29, cy - h * 0.02, cx + w * 0.29, cy + h * 0.16), const Radius.circular(10)));
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_RainyPainter old) => old.t != t;
}

class CloudySunIcon extends StatefulWidget {
  final double size;
  const CloudySunIcon({super.key, this.size = 40});
  @override
  State<CloudySunIcon> createState() => _CloudySunIconState();
}

class _CloudySunIconState extends State<CloudySunIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _ctrl, builder: (_, __) => CustomPaint(size: Size(widget.size, widget.size), painter: _CloudySunPainter(t: _ctrl.value)));
}

class _CloudySunPainter extends CustomPainter {
  final double t;
  _CloudySunPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final floatY = math.sin(t * math.pi * 2) * 3.0;
    final sunCenter = Offset(w * 0.30, h * 0.34 + floatY * 0.4);
    canvas.drawCircle(sunCenter, w * 0.22, Paint()..color = const Color(0xFFFDE68A).withOpacity(0.30)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    final rayPaint = Paint()..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + t * math.pi * 2;
      final isLong = i % 2 == 0;
      rayPaint..color = const Color(0xFFFDE68A).withOpacity(isLong ? 0.9 : 0.5)..strokeWidth = isLong ? 2.2 : 1.6;
      canvas.drawLine(sunCenter.translate(math.cos(angle) * w * 0.16, math.sin(angle) * w * 0.16), sunCenter.translate(math.cos(angle) * w * (isLong ? 0.26 : 0.22), math.sin(angle) * w * (isLong ? 0.26 : 0.22)), rayPaint);
    }
    canvas.drawCircle(sunCenter, w * 0.12, Paint()..shader = RadialGradient(colors: [const Color(0xFFFCD34D), const Color(0xFFF59E0B)]).createShader(Rect.fromCircle(center: sunCenter, radius: w * 0.12)));
    final cloudCx = w * 0.57; final cloudCy = h * 0.52 + floatY;
    _drawCloud(canvas, cloudCx, cloudCy, w, h, Paint()..color = Colors.white.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    _drawCloud(canvas, cloudCx, cloudCy, w, h, Paint()..shader = LinearGradient(colors: [Colors.white.withOpacity(0.97), Colors.white.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(Rect.fromLTWH(cloudCx - w * 0.28, cloudCy - h * 0.18, w * 0.56, h * 0.40)));
  }
  void _drawCloud(Canvas canvas, double cx, double cy, double w, double h, Paint paint) {
    final path = ui.Path();
    path.addOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.48, height: h * 0.26));
    path.addOval(Rect.fromCenter(center: Offset(cx - w * 0.16, cy + h * 0.04), width: w * 0.26, height: h * 0.20));
    path.addOval(Rect.fromCenter(center: Offset(cx + w * 0.15, cy + h * 0.05), width: w * 0.22, height: h * 0.17));
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - w * 0.24, cy, cx + w * 0.24, cy + h * 0.14), const Radius.circular(8)));
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_CloudySunPainter old) => old.t != t;
}

class SunnyIcon extends StatefulWidget {
  final double size;
  const SunnyIcon({super.key, this.size = 40});
  @override
  State<SunnyIcon> createState() => _SunnyIconState();
}

class _SunnyIconState extends State<SunnyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _ctrl, builder: (_, __) => CustomPaint(size: Size(widget.size, widget.size), painter: _SunnyPainter(t: _ctrl.value)));
}

class _SunnyPainter extends CustomPainter {
  final double t;
  _SunnyPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final pulse = math.sin(t * math.pi * 2) * 0.07 + 1.0;
    canvas.drawCircle(center, w * 0.44 * pulse, Paint()..color = const Color(0xFFFDE68A).withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawCircle(center, w * 0.33 * pulse, Paint()..color = const Color(0xFFFCD34D).withOpacity(0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    final rayAngle = t * math.pi * 2;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 + rayAngle;
      final isLong = i % 2 == 0;
      canvas.drawLine(center.translate(math.cos(angle) * w * 0.28, math.sin(angle) * w * 0.28), center.translate(math.cos(angle) * w * (isLong ? 0.44 : 0.38), math.sin(angle) * w * (isLong ? 0.44 : 0.38)), Paint()..color = const Color(0xFFFDE68A).withOpacity(isLong ? 0.92 : 0.55)..strokeWidth = isLong ? 2.6 : 1.8..strokeCap = StrokeCap.round);
    }
    canvas.drawCircle(center, w * 0.23, Paint()..shader = RadialGradient(colors: [const Color(0xFFFBBF24), const Color(0xFFF59E0B), const Color(0xFFD97706)], stops: const [0.0, 0.65, 1.0]).createShader(Rect.fromCircle(center: center, radius: w * 0.23)));
    canvas.drawCircle(center.translate(-w * 0.07, -h * 0.07), w * 0.09, Paint()..color = Colors.white.withOpacity(0.42));
  }
  @override
  bool shouldRepaint(_SunnyPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════
//  LANDING PAGE — Map fullscreen
// ══════════════════════════════════════════════════════════════
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {

  // ── Nav & notif ──────────────────────────────────────────────
  int _activeNav = 0;
  int _unreadNotif = 0;
  bool _showCriticalBanner = false;
  String _bannerMessage = '';

  // ── Cuaca ────────────────────────────────────────────────────
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  // ── GPS & Map ────────────────────────────────────────────────
  final MapController _mapController = MapController();
  Position? _userPosition;
  final LatLng _medanCenter = const LatLng(3.5952, 98.6722);
  late LatLng _currentMapCenter;
  bool _isPinMode = false; // true = user sedang geser pin tujuan

  // ── Search ───────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;
  // mapbox_id per suggestion label (dipakai untuk /retrieve)
  Map<String, String> _suggestionMapboxIds = {};
  // tujuan yang sudah dipilih user, menunggu tombol analisis
  String? _selectedDestLabel;
  LatLng? _selectedDestCoords;

  // ── Prediksi rute ────────────────────────────────────────────
  // _routeState: 'idle' | 'loading' | 'result'
  String _routeState = 'idle';
  LatLng? _destPoint;
  List<LatLng> _routePolyline = [];
  Map<String, dynamic>? _predictionData;

  // ── Onboarding ───────────────────────────────────────────────
  final _keyNotif       = GlobalKey();
  final _keyWeather     = GlobalKey();
  final _keySearch      = GlobalKey();
  final _keyAngkot      = GlobalKey();
  static const _kOnboardingDone = 'onboarding_done';
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    _currentMapCenter = _medanCenter;
    _checkNotifications();
    _fetchWeather();
    _determinePosition();
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────
  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _userPosition = position);
        _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
        _currentMapCenter = LatLng(position.latitude, position.longitude);
      }
    }
  }

  // ── Onboarding ───────────────────────────────────────────────
  Future<void> _maybeShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kOnboardingDone) ?? false) {
      if (mounted) setState(() => _onboardingDone = true);
      return;
    }
    if (mounted) Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && !_onboardingDone) _startOnboarding();
    });
  }

  void _startOnboarding() {
    OnboardingOverlay.show(
      context: context,
      steps: [
        OnboardingStep(targetKey: _keyNotif, icon: OnboardingIcon.notification, title: 'Notifikasi & Peringatan', description: 'Dapatkan alert kemacetan parah dan info penting secara real-time.', padding: const EdgeInsets.all(6)),
        OnboardingStep(targetKey: _keyWeather, icon: OnboardingIcon.weather, title: 'Cuaca Real-time Medan', description: 'Pantau suhu dan kondisi cuaca langsung dari halaman utama.', padding: const EdgeInsets.all(8)),
        OnboardingStep(targetKey: _keySearch, icon: OnboardingIcon.route, title: 'Cari Rute Pintar', description: 'Ketik tujuan atau geser pin untuk prediksi waktu tempuh & kondisi lalu lintas.', padding: const EdgeInsets.all(6)),
        OnboardingStep(targetKey: _keyAngkot, icon: OnboardingIcon.angkot, title: 'Live Angkot', description: 'Posisi angkot real-time beserta estimasi waktu kedatangan.', padding: const EdgeInsets.all(6)),
      ],
      onFinished: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kOnboardingDone, true);
        if (mounted) setState(() => _onboardingDone = true);
      },
    );
  }

  // ── Notifikasi ───────────────────────────────────────────────
  Future<void> _checkNotifications() async {
    try {
      final data = await ApiService().getNotifications();
      setState(() {
        _unreadNotif = data['unread_count'] as int;
        if (_unreadNotif > 0) {
          _showCriticalBanner = true;
          _bannerMessage = data['alerts'][0]['message'] as String;
        }
      });
    } catch (e) { debugPrint('Notif failed: $e'); }
  }

  // ── Cuaca ────────────────────────────────────────────────────
  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(Uri.parse('${ApiService().baseUrl}/weather/current'));
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(response.body) as Map<String, dynamic>;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Weather failed: $e');
      setState(() => _isLoadingWeather = false);
    }
  }

  // ── Mapbox Search ────────────────────────────────────────────
  Future<void> _searchMapbox(String query) async {
    if (query.length < 2) return;
    final uri = Uri.parse('https://api.mapbox.com/search/searchbox/v1/suggest').replace(queryParameters: {
      'q': query,
      'proximity': '98.6722,3.5952',
      'bbox': '98.3,3.0,99.2,4.3',
      'language': 'id',
      'limit': '6',
      'session_token': 'medan-flow-session',
      'access_token': AppConfig.mapboxToken,
    });
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final suggestions = data['suggestions'] as List;
        final List<Map<String, dynamic>> results = [];
        _suggestionMapboxIds.clear();
        for (var s in suggestions) {
          final label = s['name'] + (s['place_formatted'] != null ? ', ${s['place_formatted']}' : '');
          final mapboxId = s['mapbox_id'] as String? ?? '';
          results.add({'label': label, 'icon': _iconForCategory(s['feature_type'] ?? ''), 'mapbox_id': mapboxId});
          if (mapboxId.isNotEmpty) _suggestionMapboxIds[label] = mapboxId;
        }
        if (mounted) setState(() {
          _searchSuggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      }
    } catch (e) { debugPrint('Search error: $e'); }
  }

  // Retrieve koordinat aktual dari Mapbox setelah user pilih suggestion
  Future<LatLng?> _retrieveMapboxCoords(String mapboxId) async {
    try {
      final uri = Uri.parse(
        'https://api.mapbox.com/search/searchbox/v1/retrieve/$mapboxId'
      ).replace(queryParameters: {
        'session_token': 'medan-flow-session',
        'access_token': AppConfig.mapboxToken,
      });
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final coords = features[0]['geometry']['coordinates'] as List;
          return LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
        }
      }
    } catch (e) { debugPrint('Retrieve error: $e'); }
    return null;
  }

  IconData _iconForCategory(String type) {
    switch (type) {
      case 'poi': return Icons.place_rounded;
      case 'address': return Icons.location_on_rounded;
      default: return Icons.search_rounded;
    }
  }

  void _onSearchChanged(String v) {
    if (v.trim().isEmpty) {
      setState(() { _searchSuggestions = []; _showSuggestions = false; });
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _searchMapbox(v));
  }

  Future<void> _selectSuggestion(String label) async {
    _searchCtrl.text = label;
    _searchFocus.unfocus();
    setState(() {
      _showSuggestions = false;
      _selectedDestLabel = label;
      _selectedDestCoords = null;
    });
    final mapboxId = _suggestionMapboxIds[label];
    if (mapboxId != null && mapboxId.isNotEmpty) {
      final coords = await _retrieveMapboxCoords(mapboxId);
      if (coords != null && mounted) {
        setState(() => _selectedDestCoords = coords);
        _mapController.move(coords, 14.5);
      }
    }
  }

  // ── Pin mode ─────────────────────────────────────────────────
  void _togglePinMode() {
    setState(() {
      _isPinMode = !_isPinMode;
      if (_isPinMode) {
        _searchCtrl.clear();
        _showSuggestions = false;
        _searchFocus.unfocus();
      }
    });
  }

  void _confirmPin() {
    _runPrediction(_currentMapCenter, label: 'Titik di Peta');
    setState(() => _isPinMode = false);
  }

  // ── Panggil API prediksi ─────────────────────────────────────
  Future<void> _runPrediction(LatLng dest, {String label = ''}) async {
    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS belum siap, tunggu sebentar...'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() { _routeState = 'loading'; _destPoint = dest; _predictionData = null; _routePolyline = []; });

    try {
      final response = await ApiService().getTravelPrediction(
        _userPosition!.latitude,
        _userPosition!.longitude,
        dest.latitude,
        dest.longitude,
      );
      List<LatLng> points = [];
      if (response['route_geometry'] != null) {
        for (var p in response['route_geometry']) {
          points.add(LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()));
        }
      } else {
        points = [LatLng(_userPosition!.latitude, _userPosition!.longitude), dest];
      }
      if (mounted) {
        setState(() {
          _predictionData = response;
          _predictionData!['dest_label'] = label;
          _routePolyline = points;
          _routeState = 'result';
        });
        _mapController.move(
          LatLng((_userPosition!.latitude + dest.latitude) / 2, (_userPosition!.longitude + dest.longitude) / 2),
          13.0,
        );
      }
    } catch (e) {
      debugPrint('Prediction error: $e');
      if (mounted) {
        setState(() => _routeState = 'idle');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menganalisis rute. Cek koneksi.'), backgroundColor: Color(0xFFDC2626), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _resetRoute() {
    setState(() {
      _routeState = 'idle';
      _destPoint = null;
      _routePolyline = [];
      _predictionData = null;
      _searchCtrl.clear();
      _isPinMode = false;
      _selectedDestLabel = null;
      _selectedDestCoords = null;
    });
    if (_userPosition != null) {
      _mapController.move(LatLng(_userPosition!.latitude, _userPosition!.longitude), 15.0);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'red':    return const Color(0xFFDC2626);
      case 'orange': return const Color(0xFFEA580C);
      case 'blue':   return const Color(0xFF2563EB);
      default:       return const Color(0xFF16A34A);
    }
  }

  Widget _buildWeatherIcon(String iconType) {
    switch (iconType) {
      case 'rainy':  return const RainyWeatherIcon(size: 28);
      case 'cloudy': return const CloudySunIcon(size: 28);
      default:       return const SunnyIcon(size: 28);
    }
  }

  String _getDateString() {
    final now = DateTime.now();
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          _searchFocus.unfocus();
          setState(() => _showSuggestions = false);
        },
        child: Stack(
          children: [
            // ── 1. PETA FULLSCREEN ────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _medanCenter,
                initialZoom: 15.0,
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture) setState(() => _currentMapCenter = pos.center!);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/traffic-day-v2/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxToken}',
                  userAgentPackageName: 'com.medanflow.app',
                ),
                // Rute polyline
                if (_routePolyline.isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(points: _routePolyline, color: _P.b600, strokeWidth: 5.5, strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round),
                  ]),
                // Marker GPS user + tujuan
                MarkerLayer(markers: [
                  if (_userPosition != null)
                    Marker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      width: 44, height: 44,
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _P.b600,
                          boxShadow: [BoxShadow(color: _P.b600.withOpacity(0.4), blurRadius: 10)]),
                        child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  if (_destPoint != null && _routeState == 'result')
                    Marker(
                      point: _destPoint!,
                      width: 44, height: 44,
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFDC2626),
                          boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.4), blurRadius: 10)]),
                        child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                ]),
              ],
            ),

            // ── 2. PIN MODE CENTER CROSSHAIR ──────────────────
            if (_isPinMode)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 44),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _P.ink.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Geser peta ke tujuan', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 6),
                      Icon(Icons.location_on_rounded, color: const Color(0xFFEA580C), size: 52,
                        shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                    ],
                  ),
                ),
              ),

            // ── 3. HEADER TRANSPARAN ──────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Kiri: nama app + tanggal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MedFlow',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 8)])),
                          Text(_getDateString(),
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.80), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    // Tengah: pill cuaca ringkas
                    if (!_isLoadingWeather && _weatherData != null)
                      KeyedSubtree(
                        key: _keyWeather,
                        child: GestureDetector(
                          onTap: () {}, // bisa expand ke detail cuaca
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 28, height: 28,
                                  child: _buildWeatherIcon(_weatherData!['icon'] as String? ?? 'sunny')),
                                const SizedBox(width: 7),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_weatherData!['temp'] as String? ?? '--',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                                    Text(_weatherData!['condition'] as String? ?? '--',
                                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    // Kanan: tombol notif
                    Container(
                      key: _keyNotif,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
                          ),
                          child: Stack(children: [
                            const Center(child: Icon(Icons.notifications_none_outlined, color: Colors.white, size: 20)),
                            if (_unreadNotif > 0)
                              Positioned(top: 9, right: 9,
                                child: Container(width: 8, height: 8,
                                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5)))),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 4. BANNER ALERT ───────────────────────────────
            if (_showCriticalBanner)
              Positioned(
                top: topPad + 80, left: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2).withOpacity(0.96),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_bannerMessage, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w700))),
                    GestureDetector(
                      onTap: () => setState(() => _showCriticalBanner = false),
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('✕', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
                    ),
                  ]),
                ),
              ),

            // ── 5. SEARCH BAR + SUGGESTIONS ──────────────────
            if (_routeState != 'result')
              Positioned(
                top: topPad + (_showCriticalBanner ? 130 : 80),
                left: 16, right: 16,
                child: KeyedSubtree(
                  key: _keySearch,
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 20, offset: const Offset(0, 4))],
                        ),
                        child: Row(children: [
                          const SizedBox(width: 16),
                          Icon(_isPinMode ? Icons.push_pin_rounded : Icons.search_rounded,
                            color: _isPinMode ? const Color(0xFFEA580C) : _P.b500, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              focusNode: _searchFocus,
                              onChanged: _onSearchChanged,
                              enabled: !_isPinMode,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _P.ink),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                hintText: _isPinMode ? 'Geser peta, lalu konfirmasi...' : 'Mau pergi ke mana?',
                                hintStyle: TextStyle(color: _P.ink4, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          ),
                          // Tombol pin mode
                          GestureDetector(
                            onTap: _togglePinMode,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isPinMode ? const Color(0xFFEA580C).withOpacity(0.1) : _P.b50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.location_on_rounded,
                                color: _isPinMode ? const Color(0xFFEA580C) : _P.ink3, size: 18),
                            ),
                          ),
                          // Tombol konfirmasi pin
                          if (_isPinMode)
                            GestureDetector(
                              onTap: _confirmPin,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEA580C),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                            ),
                        ]),
                      ),
                      // Suggestions dropdown
                      if (_showSuggestions && _searchSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: _searchSuggestions.map((s) => InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _selectSuggestion(s['label'] as String),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(children: [
                                  Icon(s['icon'] as IconData, size: 16, color: _P.b500),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(s['label'] as String,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _P.ink),
                                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ]),
                              ),
                            )).toList(),
                          ),
                        ),
                      // ── Tombol Analisis (muncul setelah tujuan dipilih) ──
                      if (_selectedDestLabel != null && !_showSuggestions)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _P.b600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 4,
                              shadowColor: _P.b600.withOpacity(0.4),
                            ),
                            onPressed: _selectedDestCoords == null
                                ? null // masih loading koordinat
                                : () => _runPrediction(_selectedDestCoords!, label: _selectedDestLabel!),
                            icon: _selectedDestCoords == null
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.route_rounded, color: Colors.white, size: 18),
                            label: Text(
                              _selectedDestCoords == null ? 'Mendapatkan koordinat...' : 'ANALISIS ESTIMASI WAKTU',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.3),
                            ),
                          ),
                        ),
                      // Tombol clear tujuan
                      if (_selectedDestLabel != null && !_showSuggestions)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDestLabel = null;
                              _selectedDestCoords = null;
                              _searchCtrl.clear();
                            });
                          },
                          icon: const Icon(Icons.close_rounded, size: 14, color: _P.ink4),
                          label: const Text('Ganti tujuan', style: TextStyle(fontSize: 12, color: _P.ink4, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ),

            // ── 6. LOADING INDICATOR ──────────────────────────
            if (_routeState == 'loading')
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _P.b600.withOpacity(0.15), blurRadius: 20)],
                  ),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: _P.b600, strokeWidth: 3),
                    SizedBox(height: 14),
                    Text('Menganalisis rute...', style: TextStyle(fontWeight: FontWeight.w700, color: _P.ink, fontSize: 13)),
                  ]),
                ),
              ),

            // ── 7. RESULT BOTTOM SHEET ────────────────────────
            if (_routeState == 'result' && _predictionData != null)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _buildResultSheet(),
              ),

            // ── 8. BOTTOM NAV ─────────────────────────────────
            if (_routeState != 'result')
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _buildBottomNav(),
              ),

            // ── 9. TOMBOL ZOOM ────────────────────────────────
            Positioned(
              right: 16,
              bottom: _routeState == 'result' ? 320 : 110,
              child: Column(children: [
                _zoomBtn(Icons.add_rounded, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                const SizedBox(height: 8),
                _zoomBtn(Icons.remove_rounded, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                const SizedBox(height: 8),
                // Tombol kembali ke lokasi user
                _zoomBtn(Icons.my_location_rounded, () {
                  if (_userPosition != null) {
                    _mapController.move(LatLng(_userPosition!.latitude, _userPosition!.longitude), 15.0);
                  }
                }),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  RESULT SHEET — tampil setelah prediksi berhasil
  // ════════════════════════════════════════════════════════════
  Widget _buildResultSheet() {
    final data = _predictionData!;
    final statusColor = _getStatusColor(data['status_color'] as String? ?? 'green');
    final factors = data['prediction_factors'] as Map<String, dynamic>? ?? {};

    return Container(
      decoration: const BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Color(0x1A2563EB), blurRadius: 32, offset: Offset(0, -6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: _P.b100, borderRadius: BorderRadius.circular(10))),
          ),
          // Label tujuan
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              const Icon(Icons.flag_rounded, color: Color(0xFFDC2626), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(data['dest_label'] as String? ?? 'Tujuan',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _P.ink2),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              GestureDetector(
                onTap: _resetRoute,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _P.b50, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _P.b200, width: 1)),
                  child: const Text('Ganti Rute', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _P.b600)),
                ),
              ),
            ]),
          ),
          // Kartu utama biru
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_P.b600, _P.b800, _P.dark], stops: [0.0, 0.55, 1.0], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: _P.b600.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ESTIMASI PERJALANAN', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(data['predicted_time'] as String? ?? '--',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                const SizedBox(height: 4),
                Text('Normal: ${data['normal_time'] as String? ?? '--'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: Text(
                  (data['congestion_level'] as String? ?? '--').toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ]),
          ),
          // 3 stat card: jarak, cuaca, delay
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              _statCard(Icons.route_outlined, 'Jarak', data['distance'] as String? ?? '--', [_P.b50, _P.b100], _P.b500),
              const SizedBox(width: 10),
              _statCard(Icons.cloud_queue_rounded, 'Cuaca', factors['weather'] as String? ?? '--',
                [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)], const Color(0xFF0EA5E9)),
              const SizedBox(width: 10),
              _statCard(Icons.timer_outlined, 'Delay', data['delay'] as String? ?? '--',
                [const Color(0xFFFFF7ED), const Color(0xFFFED7AA)], const Color(0xFFEA580C)),
            ]),
          ),
          // Confidence + traffic source
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              Icon(Icons.verified_rounded, size: 13, color: _P.ink4),
              const SizedBox(width: 5),
              Text('${factors['traffic_source'] ?? 'Mapbox Traffic'} • Akurasi ${factors['confidence_level'] ?? '--'}',
                style: const TextStyle(fontSize: 11, color: _P.ink4, fontWeight: FontWeight.w500)),
            ]),
          ),
          // Tombol navigasi + bottom padding
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
            child: Row(children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _P.b600,
                      side: const BorderSide(color: _P.b200, width: 1.5),
                      backgroundColor: _P.b50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _resetRoute,
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: _P.b600),
                    label: const Text('Rute Lain', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _P.b600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _P.b600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RouteRecommendationScreen())),
                    icon: const Icon(Icons.directions_rounded, size: 18, color: Colors.white),
                    label: const Text('Detail Rute', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, List<Color> bg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _P.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.b100, width: 1.5),
          boxShadow: [BoxShadow(color: _P.b500.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: iconColor, size: 16)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: _P.ink3, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: _P.ink, height: 1.2)),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  BOTTOM NAV
  // ════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.05)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _P.b500.withOpacity(0.14), width: 1.5),
          boxShadow: [
            BoxShadow(color: _P.b500.withOpacity(0.14), blurRadius: 32, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          _nbItem(0, Icons.home_rounded, 'Beranda', onTap: () {}),
          _nbItem(1, Icons.directions_bus_filled, 'Angkot',
            key: _keyAngkot,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AngkotTrackingScreen()))),
          _nbFab(),
          _nbItem(3, Icons.show_chart_rounded, 'Kemacetan',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrafficHeatmapScreen()))),
          _nbItem(4, Icons.lock_outline_rounded, 'Login',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
        ]),
      ),
    );
  }

  Widget _nbItem(int idx, IconData icon, String label, {required VoidCallback onTap, Key? key}) {
    final on = _activeNav == idx;
    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: () { setState(() => _activeNav = idx); onTap(); },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: on ? _P.b50 : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: on ? _P.b600 : _P.ink4, size: 20),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: on ? _P.b600 : _P.ink4)),
          ]),
        ),
      ),
    );
  }

  Widget _nbFab() {
    return GestureDetector(
      onTap: () {
        // FAB = shortcut buka search / mulai cari rute
        _searchFocus.requestFocus();
      },
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_P.b500, _P.b700], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _P.b600.withOpacity(0.40), blurRadius: 18, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: _P.ink2, size: 20),
      ),
    );
  }
}