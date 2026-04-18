<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Route;
use Illuminate\Http\Request;

class RecommendationController extends Controller
{
    public function getRecommendations(Request $request)
    {
        try {
            $destName = $request->query('dest');
            $userLat = $request->query('lat');
            $userLng = $request->query('lng');

            $routes = Route::all();
            if ($routes->isEmpty()) {
                return response()->json([
                    'message' => 'Data rute tidak ditemukan.'
                ], 404);
            }

            $locations = [
                "Pinang Baris"   => ["lat" => 3.6031,  "lng" => 98.6250],
                "Amplas"         => ["lat" => 3.5401,  "lng" => 98.6998],
                "Lapangan Merdeka" => ["lat" => 3.5952, "lng" => 98.6722],
                "Carrefour Multatuli" => ["lat" => 3.5800, "lng" => 98.6600],
                "Sunggal"        => ["lat" => 3.6200,  "lng" => 98.6400],
                "Helvetia"       => ["lat" => 3.6350,  "lng" => 98.6300],
                "Padang Bulan"   => ["lat" => 3.5750,  "lng" => 98.6850],
                "Kampung Lalang" => ["lat" => 3.6100,  "lng" => 98.6500],
                "Marelan"        => ["lat" => 3.6800,  "lng" => 98.6600],
                "Belawan"        => ["lat" => 3.7800,  "lng" => 98.6900],
                "Polonia"        => ["lat" => 3.5600,  "lng" => 98.6780],
                "Aksara"         => ["lat" => 3.5500,  "lng" => 98.7100],
                "Pancing"        => ["lat" => 3.5300,  "lng" => 98.7300],
                "Pasar Petisah"  => ["lat" => 3.5900,  "lng" => 98.6650],
                "Tembung"        => ["lat" => 3.5700,  "lng" => 98.7500],
                "Delitua"        => ["lat" => 3.5100,  "lng" => 98.7200],
                "Sei Sikambing"  => ["lat" => 3.6000,  "lng" => 98.6550],
            ];

            $target = $locations[$destName] ?? ["lat" => 3.6031, "lng" => 98.6250];

            $recommendations = $routes->map(function ($route) use ($target, $userLat, $userLng) {

                // --- LOGIKA PERHITUNGAN DINAMIS ---
                $distKm = 0;
                $etaMinutes = 20; // default

                if ($userLat && $userLng) {
                    // 1. Hitung jarak lurus (Haversine) dari GPS User ke Tujuan
                    $distKm = $this->calculateDistance($userLat, $userLng, $target['lat'], $target['lng']);

                    // 2. Estimasi Waktu (Asumsi kecepatan rata-rata angkot Medan + macet = 18 km/jam)
                    // Rumus: (Jarak / Kecepatan) * 60 menit
                    $etaMinutes = ($distKm / 18) * 60;
                } else {
                    $distKm = $route->distance;
                    $etaMinutes = ($distKm / 18) * 60;
                }

                return [
                    'id'       => $route->id,
                    'name'     => $route->name,
                    'distance' => round($distKm, 1) . " km",
                    'eta'      => round($etaMinutes) . " Menit",
                    'congestion' => $etaMinutes > 40 ? 'high' : 'low',
                    'dest_lat' => $target['lat'],
                    'dest_lng' => $target['lng'],
                    // Kita sertakan geometri garis lurus sebagai fallback awal
                    'geometry' => [
                        [$userLng ?? 98.6722, $userLat ?? 3.5952],
                        [$target['lng'], $target['lat']]
                    ]
                ];
            });

            return response()->json($recommendations);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Terjadi kesalahan sistem.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rumus Haversine untuk menghitung jarak antara 2 koordinat GPS
     */
    private function calculateDistance($lat1, $lon1, $lat2, $lon2) {
        $earthRadius = 6371; // km
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat/2) * sin($dLat/2) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon/2) * sin($dLon/2);
        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        return $earthRadius * $c;
    }
}
