<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\MLPredictionService;
use App\Services\GeminiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PredictionController extends Controller
{
    private MLPredictionService $ml;
    private GeminiService $gemini;

    public function __construct(MLPredictionService $ml, GeminiService $gemini)
    {
        $this->ml     = $ml;
        $this->gemini = $gemini;
    }

    /**
     * POST /api/predict/travel-time
     *
     * Body: { origin_lat, origin_lng, dest_lat, dest_lng }
     */
    public function getTravelTimePrediction(Request $request)
    {
        $request->validate([
            'origin_lat' => 'required|numeric',
            'origin_lng' => 'required|numeric',
            'dest_lat'   => 'required|numeric',
            'dest_lng'   => 'required|numeric',
        ]);

        $originLat = (float) $request->origin_lat;
        $originLng = (float) $request->origin_lng;
        $destLat   = (float) $request->dest_lat;
        $destLng   = (float) $request->dest_lng;

        // ── 1. Ambil rute dari OSRM ──────────────────────────
        $osrmData = $this->fetchOSRMRoute($originLat, $originLng, $destLat, $destLng);
        if (!$osrmData) {
            return response()->json(['error' => 'Gagal mengambil data rute.'], 500);
        }

        $distanceKm      = round($osrmData['distance'] / 1000, 1);
        $durationNormal  = (int) ($osrmData['duration'] / 60); // menit
        $encodedPolyline = $osrmData['encoded_polyline'];

        // ── 2. Ambil cuaca dari OpenWeatherMap ───────────────
        $weather     = $this->fetchWeatherCondition($originLat, $originLng);
        $weatherMain = strtolower($weather['main'] ?? 'clear');

        // ── 3. Prediksi ML ───────────────────────────────────
        $mlResult   = $this->ml->predict($originLat, $originLng, $destLat, $destLng, $weatherMain);
        $multiplier = $mlResult['travel_multiplier'];

        // ── 4. Hitung estimasi waktu ─────────────────────────
        $predictedMinutes = (int) round($durationNormal * $multiplier);
        $delayMinutes     = max(0, $predictedMinutes - $durationNormal);

        $predictedTime = $this->formatDuration($predictedMinutes);
        $normalTime    = $this->formatDuration($durationNormal);
        $delayText     = $delayMinutes > 0 ? "+{$delayMinutes} menit" : 'Tidak ada';

        // ── 5. Build response ────────────────────────────────
        return response()->json([
            // Estimasi waktu
            'predicted_time'   => $predictedTime,
            'normal_time'      => $normalTime,
            'delay'            => $delayText,
            'distance'         => $distanceKm . ' km',

            // ML result
            'congestion_level' => $mlResult['congestion_level'],
            'status_color'     => $mlResult['status_color'],
            'travel_multiplier'=> $multiplier,

            // Polyline rute
            'encoded_polyline' => $encodedPolyline,

            // Faktor prediksi (untuk UI)
            'prediction_factors' => array_merge(
                $mlResult['prediction_factors'],
                [
                    'weather'          => $weather['description'] ?? 'Tidak diketahui',
                    'confidence_level' => $mlResult['confidence_level'],
                    'traffic_source'   => $mlResult['traffic_source'],
                ]
            ),

            // Debug info (hapus di production)
            'ml_features' => $mlResult['ml_features'],
        ]);
    }

    // ── OSRM: Ambil rute gratis tanpa API key ─────────────────────────────

    private function fetchOSRMRoute(float $lat1, float $lng1, float $lat2, float $lng2): ?array
    {
        try {
            $url = "https://router.project-osrm.org/route/v1/driving/{$lng1},{$lat1};{$lng2},{$lat2}";
            $response = Http::timeout(10)->get($url, [
                'overview'   => 'full',
                'geometries' => 'polyline',
                'steps'      => 'false',
            ]);

            if ($response->successful()) {
                $data  = $response->json();
                $route = $data['routes'][0] ?? null;
                if (!$route) return null;

                $distanceKm = $route['distance'] / 1000;
                $duration   = $route['duration']; // detik dari OSRM

                // ── Koreksi realistis untuk jalan Sumatera ──────
                // OSRM terlalu optimis, tambah faktor berdasarkan jarak
                if ($distanceKm > 100) {
                    // Jarak jauh: jalan antar kota Sumatera, banyak tikungan
                    // Asumsikan kecepatan rata-rata 55 km/h (lebih realistis)
                    $duration = ($distanceKm / 55) * 3600;
                } elseif ($distanceKm > 30) {
                    // Jarak menengah: keluar kota
                    $duration = ($distanceKm / 45) * 3600;
                }
                // Dalam kota (<30km): pakai durasi OSRM langsung

                return [
                    'distance'         => $route['distance'],
                    'duration'         => $duration,
                    'encoded_polyline' => $route['geometry'],
                ];
            }

            Log::error('OSRM failed: ' . $response->status());
            return null;

        } catch (\Exception $e) {
            Log::error('OSRM Exception: ' . $e->getMessage());
            return null;
        }
    }

    // ── OpenWeatherMap ────────────────────────────────────────────────────

    private function fetchWeatherCondition(float $lat, float $lng): array
    {
        try {
            $apiKey   = env('OPENWEATHERMAP_API_KEY');
            $response = Http::timeout(8)->get('https://api.openweathermap.org/data/2.5/weather', [
                'lat'   => $lat,
                'lon'   => $lng,
                'appid' => $apiKey,
                'lang'  => 'id',
                'units' => 'metric',
            ]);

            if ($response->successful()) {
                $data = $response->json();
                return [
                    'main'        => $data['weather'][0]['main'] ?? 'Clear',
                    'description' => $data['weather'][0]['description'] ?? 'Cerah',
                    'temp'        => $data['main']['temp'] ?? null,
                ];
            }
        } catch (\Exception $e) {
            Log::warning('Weather fetch failed: ' . $e->getMessage());
        }

        return ['main' => 'Clear', 'description' => 'Cerah'];
    }

    // ── Format durasi menit → "X jam Y menit" ────────────────────────────

    private function formatDuration(int $minutes): string
    {
        if ($minutes < 60) return $minutes . ' menit';
        $h = intdiv($minutes, 60);
        $m = $minutes % 60;
        return $m > 0 ? "{$h} jam {$m} menit" : "{$h} jam";
    }
}
