<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Route;
use Illuminate\Http\Request;

class RecommendationController extends Controller
{
    public function getRecommendations(Request $request)
    {
        $destName = $request->query('dest');
        $userLat  = $request->query('lat');
        $userLng  = $request->query('lng');
        $destLat  = $request->query('dest_lat');  // ← baru
        $destLng  = $request->query('dest_lng');  // ← baru

        $routes = Route::all();
        if ($routes->isEmpty()) {
            return response()->json(['message' => 'Data rute tidak ditemukan.'], 404);
        }

        $target = [
            'lat' => $destLat ?? 3.6031,
            'lng' => $destLng ?? 98.6250,
        ];

        $recommendations = $routes->map(function ($route) use ($target, $userLat, $userLng) {
            $distKm = $userLat && $userLng
                ? $this->calculateDistance($userLat, $userLng, $target['lat'], $target['lng'])
                : $route->distance;

            $etaMinutes = ($distKm / 18) * 60;

            return [
                'id'         => $route->id,
                'name'       => $route->name,
                'distance'   => round($distKm, 1) . " km",
                'eta'        => round($etaMinutes) . " Menit",
                'congestion' => $etaMinutes > 40 ? 'high' : 'low',
                'dest_lat'   => $target['lat'],
                'dest_lng'   => $target['lng'],
                'geometry'   => [
                    [$userLng ?? 98.6722, $userLat ?? 3.5952],
                    [$target['lng'], $target['lat']]
                ]
            ];
        })->values();

        return response()->json($recommendations);
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
