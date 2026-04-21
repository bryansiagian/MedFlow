<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Services\GeminiService;
use App\Models\UserReport;
use Carbon\Carbon;

class TrafficMapController extends Controller
{
    public function getPredictiveHeatmap(Request $request)
    {
        $userLat = (float) $request->query('lat', 3.5952);
        $userLng = (float) $request->query('lng', 98.6722);
        $minutes = (int) $request->query('minutes', 5);
        $token   = env('MAPBOX_ACCESS_TOKEN');

        if (!in_array($minutes, [5, 10, 15, 20, 25, 30])) $minutes = 5;

        // 1. Ambil cuaca
        $weatherController = new WeatherController();
        $weather = $weatherController->getWeatherData();

        // 2. Ambil jalan utama dari OSM
        $bbox  = ($userLat - 0.03) . "," . ($userLng - 0.03) . "," . ($userLat + 0.03) . "," . ($userLng + 0.03);
        $query = "[out:json];way[highway~'primary|secondary|trunk']($bbox);out center geom 10;"; // ← tambah center

        try {
            $osmResp = Http::timeout(10)->asForm()->post('https://overpass-api.de/api/interpreter', ['data' => $query]);
            $osmData = $osmResp->json();
            $roadsFound = [];

            foreach ($osmData['elements'] ?? [] as $way) {
                if (!isset($way['geometry'])) continue;
                $coords = array_map(fn($p) => [$p['lon'], $p['lat']], $way['geometry']);
                $center = $way['center'] ?? [
                    'lat' => $way['geometry'][0]['lat'],
                    'lon' => $way['geometry'][0]['lon'],
                ];
                $roadsFound[] = [
                    'name'     => $way['tags']['name'] ?? 'Jalan Utama',
                    'center'   => $center,
                    'geometry' => $coords,
                ];
            }
        } catch (\Exception $e) {
            return response()->json(['data' => [], 'ai_prediction' => 'Gagal koneksi OSM.']);
        }

        // 3. Analisis trafik via Mapbox
        $predictedRoads = [];
        foreach ($roadsFound as $road) {
            try {
                $coords  = "{$userLng},{$userLat};{$road['center']['lon']},{$road['center']['lat']}";
                $resp    = Http::get(
                    "https://api.mapbox.com/directions/v5/mapbox/driving-traffic/{$coords}",
                    ['access_token' => $token]
                )->json();

                $duration = $resp['routes'][0]['duration'] ?? 0;
                $distance = $resp['routes'][0]['distance'] ?? 0;

                $congestion = 'lancar';
                if ($distance > 0 && $duration > 0) {
                    $speed = ($distance / $duration) * 3.6;
                    if ($speed < 10)      $congestion = 'macet';
                    elseif ($speed < 25)  $congestion = 'padat';
                }

                $predictedRoads[] = [
                    'name'             => $road['name'],
                    'congestion_level' => $congestion,
                    'geometry'         => $road['geometry'],
                    'lat'              => $road['center']['lat'],
                    'lng'              => $road['center']['lon'],
                ];
            } catch (\Exception $e) {
                continue;
            }
        }

        // 4. Gemini: Multiplier prediksi
        $summary      = collect($predictedRoads)->groupBy('congestion_level')->map->count();
        $futureFactor = $this->getAiFutureFactor($minutes, $summary, $weather);

        // Modifikasi level berdasarkan prediksi AI
        foreach ($predictedRoads as &$r) {
            if ($futureFactor >= 2.0 && $r['congestion_level'] == 'padat')  $r['congestion_level'] = 'sangat_macet';
            if ($futureFactor >= 1.4 && $r['congestion_level'] == 'padat')  $r['congestion_level'] = 'macet';
            if ($futureFactor >= 1.2 && $r['congestion_level'] == 'lancar' && $minutes > 15) $r['congestion_level'] = 'padat';
        }
        unset($r); // ← penting setelah foreach by reference

        // 5. Gemini: Narasi prediksi
        $gemini = new GeminiService();
        $hour   = Carbon::now('Asia/Jakarta')->addMinutes($minutes)->format('H:i');
        $aiPrediction = $gemini->analyze(
            "Kamu adalah asisten prediksi kemacetan kota Medan, Indonesia. " .
            "Prediksi trafik pukul {$hour} ({$minutes} menit lagi). " .
            "Cuaca: {$weather['condition']}. " .
            "Ringkasan kondisi jalan: " . json_encode($summary) . ". " .
            "Faktor prediksi AI: {$futureFactor}. " .
            "Berikan prediksi 2-3 kalimat singkat dalam Bahasa Indonesia dan saran praktis untuk pengguna angkot."
        );

        try {
            $incidents = \App\Models\UserReport::where('expires_at', '>', now())->get();
        } catch (\Exception $e) {
            $incidents = [];
        }

        return response()->json([
            'minutes'        => $minutes,
            'data'           => array_values($predictedRoads),
            'ai_prediction'  => $aiPrediction,
            'factor'         => $futureFactor,
            'incidents'      => $incidents,
        ]);
    }

    private function getAiFutureFactor($minutes, $summary, $weather): float
    {
        $gemini = new GeminiService();
        $prompt = "Data trafik sekarang: " . json_encode($summary) .
                  ". Cuaca: {$weather['condition']}." .
                  " Berikan angka multiplier kemacetan untuk {$minutes} menit ke depan." .
                  " Jawab ANGKA SAJA antara 0.8 sampai 2.5 (contoh: 1.3).";
        $text = trim($gemini->analyze($prompt));
        preg_match('/([0-9]+\.?[0-9]*)/', $text, $match);
        $factor = isset($match[1]) ? (float) $match[1] : 1.1;
        return max(0.8, min(2.5, $factor)); // clamp antara 0.8 - 2.5
    }
}
