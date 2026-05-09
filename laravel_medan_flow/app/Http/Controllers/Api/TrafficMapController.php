<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class TrafficMapController extends Controller
{
    public function getPredictiveHeatmap(Request $request)
    {
        $userLat = (float) $request->query('lat', 3.5952);
        $userLng = (float) $request->query('lng', 98.6722);
        $minutes = (int) $request->query('minutes', 5);

        if (!in_array($minutes, [5, 10, 15, 20, 25, 30])) $minutes = 5;

        // 1. Ambil jalan utama dari OSM
        $bbox  = ($userLat - 0.03) . "," . ($userLng - 0.03) . "," . ($userLat + 0.03) . "," . ($userLng + 0.03);
        $query = "[out:json];way[highway~'primary|secondary|trunk']($bbox);out center geom 10;";

        try {
            $osmResp = Http::timeout(10)->asForm()->post(
                'https://overpass-api.de/api/interpreter',
                ['data' => $query]
            );
            $osmData    = $osmResp->json();
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
            return response()->json([
                'minutes'       => $minutes,
                'data'          => [],
                'ai_prediction' => 'Gagal koneksi OSM.',
                'factor'        => 1.1,
                'incidents'     => [],
            ]);
        }

        // 2. Analisis trafik via ML (tanpa Google Directions / Gemini)
        $mlService      = new \App\Services\MLPredictionService();
        $predictedRoads = [];

        foreach ($roadsFound as $road) {
            try {
                $mlResult = $mlService->predict(
                    $userLat, $userLng,
                    (float) $road['center']['lat'],
                    (float) $road['center']['lon'],
                );

                $congestion = match($mlResult['congestion_level']) {
                    'Sangat Macet' => 'sangat_macet',
                    'Macet'        => 'macet',
                    'Padat'        => 'padat',
                    default        => 'lancar',
                };

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

        // 3. Hitung factor prediksi
        $summary      = collect($predictedRoads)->groupBy('congestion_level')->map->count();
        $futureFactor = round(1.1 + ($minutes / 100), 2);

        // Modifikasi level berdasarkan prediksi waktu ke depan
        foreach ($predictedRoads as &$r) {
            if ($futureFactor >= 1.4 && $r['congestion_level'] === 'padat')                    $r['congestion_level'] = 'macet';
            if ($futureFactor >= 1.2 && $r['congestion_level'] === 'lancar' && $minutes > 15) $r['congestion_level'] = 'padat';
        }
        unset($r);

        // 4. Narasi prediksi sederhana
        $macetCount   = ($summary['macet'] ?? 0) + ($summary['sangat_macet'] ?? 0);
        $padatCount   = $summary['padat'] ?? 0;
        $aiPrediction = match(true) {
            $macetCount >= 3 => "Beberapa ruas jalan diprediksi macet dalam {$minutes} menit ke depan. Disarankan berangkat lebih awal atau pilih rute alternatif.",
            $padatCount >= 3 => "Lalu lintas cukup padat dalam {$minutes} menit ke depan. Perkirakan waktu tambahan 5-10 menit.",
            default          => "Kondisi lalu lintas relatif lancar dalam {$minutes} menit ke depan.",
        };

        // 5. Incidents
        try {
            $incidents = \App\Models\UserReport::where('expires_at', '>', now())->get();
        } catch (\Exception $e) {
            $incidents = [];
        }

        return response()->json([
            'minutes'       => $minutes,
            'data'          => array_values($predictedRoads),
            'ai_prediction' => $aiPrediction,
            'factor'        => $futureFactor,
            'incidents'     => $incidents,
        ]);
    }
}
