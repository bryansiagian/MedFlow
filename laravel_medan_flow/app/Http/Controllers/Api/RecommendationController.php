<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Route;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class RecommendationController extends Controller
{
    public function getRecommendations(Request $request)
    {
        try {
            $userLat = $request->query('lat');
            $userLng = $request->query('lng');
            $destName = $request->query('dest');

            // Mengambil token dari AWS environment
            $token = env('MAPBOX_ACCESS_TOKEN');

            // 1. Validasi Token
            if (empty($token)) {
                return response()->json([
                    'message' => 'Konfigurasi Server Belum Lengkap (Token Mapbox Kosong di AWS).'
                ], 500);
            }

            // 2. Ambil Rute dari Database
            $routes = Route::all();
            if ($routes->isEmpty()) {
                return response()->json([
                    'message' => 'Data rute tidak ditemukan di database AWS. Silakan jalankan seeder.'
                ], 404);
            }

            // 3. Mapping Koordinat Tujuan (Fallback ke Pinang Baris)
            $locations = [
                "Pinang Baris" => ["lat" => 3.6031, "lng" => 98.6250],
                "Amplas" => ["lat" => 3.5401, "lng" => 98.6998],
                "Balige" => ["lat" => 2.3333, "lng" => 99.0667], // Titik testing Toba
            ];
            $target = $locations[$destName] ?? ["lat" => 3.6031, "lng" => 98.6250];
            $destLat = $target['lat'];
            $destLng = $target['lng'];

            $recommendations = $routes->map(function ($route) use ($userLat, $userLng, $destLat, $destLng, $token) {
                $geometry = [];
                $duration = 20;
                $distance = $route->distance;

                if ($userLat && $userLng) {
                    // Gunakan driving-traffic untuk akurasi kemacetan
                    $url = "https://api.mapbox.com/directions/v5/mapbox/driving-traffic/{$userLng},{$userLat};{$destLng},{$destLat}";

                    $response = Http::withoutVerifying()->get($url, [
                        'geometries'   => 'geojson',
                        'overview'     => 'full',
                        'access_token' => $token,
                    ]);

                    if ($response->successful()) {
                        $data = $response->json();
                        if (isset($data['routes'][0])) {
                            $geometry = $data['routes'][0]['geometry']['coordinates'];
                            $duration = $data['routes'][0]['duration'] / 60;
                            $distance = $data['routes'][0]['distance'] / 1000;
                        }
                    }
                }

                // Jika API Gagal tapi User ada, buat garis lurus sebagai pengaman UI
                if (empty($geometry) && $userLat) {
                    $geometry = [
                        [(float)$userLng, (float)$userLat],
                        [(float)$destLng, (float)$destLat]
                    ];
                }

                return [
                    'id' => $route->id,
                    'name' => $route->name,
                    'distance' => round($distance, 1) . " km",
                    'eta' => round($duration) . " Menit",
                    'congestion' => $duration > 30 ? 'high' : 'low',
                    'geometry' => $geometry,
                ];
            });

            return response()->json($recommendations);

        } catch (\Exception $e) {
            Log::error("Recommendation Error: " . $e->getMessage());
            return response()->json([
                'message' => 'Terjadi kesalahan sistem.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
