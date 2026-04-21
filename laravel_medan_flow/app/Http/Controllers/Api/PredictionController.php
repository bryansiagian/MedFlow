<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;

class PredictionController extends Controller
{

    public function getTravelTimePrediction(Request $request)
    {
        $request->validate([
            'origin_lat' => 'required|numeric|between:-90,90',
            'origin_lng' => 'required|numeric|between:-180,180',
            'dest_lat'   => 'required|numeric|between:-90,90',
            'dest_lng'   => 'required|numeric|between:-180,180',
        ]);

        $oriLat  = (float) $request->origin_lat;
        $oriLng  = (float) $request->origin_lng;
        $destLat = (float) $request->dest_lat;
        $destLng = (float) $request->dest_lng;

        $mapboxToken    = env('MAPBOX_ACCESS_TOKEN');
        $openweatherKey = env('OPENWEATHER_API_KEY');

        // ── 1. Mapbox Directions API (dengan annotations=duration,congestion) ──
        // annotations=congestion → per-segment congestion level (low/moderate/heavy/severe)
        // overview=full          → full route geometry untuk polyline di Flutter
        // access_token           → wajib ada
        $mapboxUrl = "https://api.mapbox.com/directions/v5/mapbox/driving-traffic/"
            . "{$oriLng},{$oriLat};{$destLng},{$destLat}"
            . "?geometries=geojson"
            . "&overview=full"
            . "&annotations=duration,congestion"
            . "&access_token={$mapboxToken}";

        try {
            $mapboxResponse = Http::timeout(10)->get($mapboxUrl);
            $mapboxData     = $mapboxResponse->json();

            if ($mapboxResponse->failed() || empty($mapboxData['routes'])) {
                return response()->json([
                    'error' => 'Mapbox gagal menghitung rute. Periksa token atau koordinat.'
                ], 500);
            }
        } catch (\Exception $e) {
            return response()->json(['error' => 'Koneksi ke Mapbox gagal: ' . $e->getMessage()], 500);
        }

        $route         = $mapboxData['routes'][0];
        $distanceKm    = $route['distance'] / 1000;

        // Mapbox driving-traffic sudah memperhitungkan real-time traffic
        // duration = waktu dengan traffic saat ini
        // duration_typical = waktu normal tanpa gangguan (jika tersedia)
        $predictedSeconds = $route['duration'];
        $normalSeconds    = $route['duration_typical'] ?? $route['duration'];
        $routeGeometry    = $route['geometry']['coordinates'] ?? [];

        // Ambil congestion dominan dari annotations per-leg
        $congestionAnnotations = $route['legs'][0]['annotation']['congestion'] ?? [];
        $dominantCongestion    = $this->getDominantCongestion($congestionAnnotations);

        // ── 2. OpenWeatherMap — cuaca aktual di titik asal ───────────
        $weatherLabel  = 'Cerah';
        $weatherFactor = 0.0; // multiplier tambahan di atas data Mapbox
        $isRaining     = false;

        try {
            $weatherResponse = Http::timeout(5)->get(
                'https://api.openweathermap.org/data/2.5/weather',
                [
                    'lat'   => $oriLat,
                    'lon'   => $oriLng,
                    'appid' => $openweatherKey,
                    'units' => 'metric',
                    'lang'  => 'id',
                ]
            );

            if ($weatherResponse->ok()) {
                $wData       = $weatherResponse->json();
                $weatherId   = $wData['weather'][0]['id'] ?? 800;
                $description = $wData['weather'][0]['description'] ?? 'cerah';
                $windspeed   = $wData['wind']['speed'] ?? 0; // m/s
                $visibility  = $wData['visibility'] ?? 10000; // meter

                // OpenWeatherMap weather condition codes:
                // 2xx = Thunderstorm, 3xx = Drizzle, 5xx = Rain, 6xx = Snow, 7xx = Atmosphere, 8xx = Clear/Clouds
                if ($weatherId >= 200 && $weatherId < 300) {
                    // Badai petir
                    $isRaining     = true;
                    $weatherFactor = 0.30;
                    $weatherLabel  = 'Badai Petir — Kecepatan sangat berkurang';
                } elseif ($weatherId >= 300 && $weatherId < 400) {
                    // Gerimis
                    $isRaining     = true;
                    $weatherFactor = 0.10;
                    $weatherLabel  = 'Gerimis — ' . ucfirst($description);
                } elseif ($weatherId >= 500 && $weatherId < 600) {
                    // Hujan
                    $isRaining     = true;
                    $weatherFactor = $weatherId >= 502 ? 0.25 : 0.15; // heavy vs light
                    $weatherLabel  = 'Hujan — ' . ucfirst($description);
                } elseif ($weatherId >= 700 && $weatherId < 800) {
                    // Kabut/asap/haze — sering terjadi di Sumatera
                    $weatherFactor = $visibility < 1000 ? 0.20 : 0.05;
                    $weatherLabel  = 'Jarak Pandang Terbatas — ' . ucfirst($description);
                } elseif ($windspeed > 10) {
                    // Angin kencang (>36 km/h)
                    $weatherFactor = 0.05;
                    $weatherLabel  = 'Angin Kencang ' . round($windspeed * 3.6) . ' km/h';
                } else {
                    $weatherLabel = ucfirst($description);
                }
            }
        } catch (\Exception $e) {
            $weatherLabel = 'Data cuaca tidak tersedia';
        }

        // ── 3. Hitung delay & status akhir ───────────────────────────
        // Base sudah dari Mapbox traffic, weather factor sebagai koreksi tambahan
        $finalPredictedSeconds = $predictedSeconds * (1 + $weatherFactor);
        $delaySeconds          = max(0, $finalPredictedSeconds - $normalSeconds);

        // Status & warna: prioritaskan data congestion dari Mapbox
        [$status, $color] = $this->resolveStatusFromCongestion(
            $dominantCongestion,
            $isRaining
        );

        // ── 4. Confidence dinamis ─────────────────────────────────────
        $now        = Carbon::now('Asia/Jakarta');
        $isWeekend  = $now->isWeekend();
        $hour       = $now->hour;
        $isPeakHour = !$isWeekend && (($hour >= 7 && $hour <= 9) || ($hour >= 16 && $hour <= 19));

        $confidence = 90; // Mapbox traffic sudah cukup akurat sebagai base
        if ($isPeakHour)          $confidence -= 8;  // traffic peak = fluktuatif
        if ($isRaining)           $confidence -= 6;
        if ($weatherFactor >= 0.25) $confidence -= 5; // cuaca ekstrem
        if ($distanceKm > 25)     $confidence -= 4;
        $confidence = max(65, min(95, $confidence));

        return response()->json([
            'route_name'         => 'Rute Tercepat (Mapbox Traffic)',
            'distance'           => round($distanceKm, 1) . ' km',
            'normal_time'        => $this->formatDuration($normalSeconds / 60),
            'predicted_time'     => $this->formatDuration($finalPredictedSeconds / 60),
            'delay'              => $delaySeconds > 60
                                        ? '+' . $this->formatDuration($delaySeconds / 60)
                                        : 'Tanpa delay berarti',
            'congestion_level'   => $status,
            'status_color'       => $color,
            'current_time'       => $now->format('H:i'),
            'route_geometry'     => $routeGeometry,
            'prediction_factors' => [
                'weather'          => $weatherLabel,
                'traffic_source'   => 'Mapbox Real-time Traffic',
                'confidence_level' => $confidence . '%',
            ],
        ]);
    }

    // ── Helper: tentukan congestion dominan dari array per-segment ──
    private function getDominantCongestion(array $annotations): string
    {
        if (empty($annotations)) return 'unknown';

        $counts = array_count_values($annotations);
        // Prioritas: severe > heavy > moderate > low
        foreach (['severe', 'heavy', 'moderate', 'low'] as $level) {
            if (isset($counts[$level]) && $counts[$level] > count($annotations) * 0.25) {
                return $level;
            }
        }
        return array_key_first($counts) ?? 'low';
    }

    // ── Helper: konversi congestion level Mapbox → status & warna app ──
    private function resolveStatusFromCongestion(string $congestion, bool $isRaining): array
    {
        return match ($congestion) {
            'severe'   => ['Macet Parah',    'red'],
            'heavy'    => ['Padat Merayap',  $isRaining ? 'red' : 'orange'],
            'moderate' => ['Agak Padat',     $isRaining ? 'orange' : 'orange'],
            'low'      => ['Lancar',         $isRaining ? 'orange' : 'green'],
            default    => ['Lancar',         'green'],
        };
    }

    // ── Helper: format menit → "X jam Y mnt" atau "Z menit" ──
    private function formatDuration(float $minutes): string
    {
        $rounded = (int) round($minutes);
        if ($rounded >= 60) {
            $h = intdiv($rounded, 60);
            $m = $rounded % 60;
            return $m > 0 ? "{$h} jam {$m} mnt" : "{$h} jam";
        }
        return "{$rounded} menit";
    }
}
