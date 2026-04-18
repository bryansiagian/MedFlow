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

            $recommendations = $routes->map(function ($route) use ($target) {
                return [
                    'id'       => $route->id,
                    'name'     => $route->name,
                    'distance' => $route->distance . " km",
                    'eta'      => $route->eta ?? "20 Menit",
                    'congestion' => 'low',
                    'dest_lat' => $target['lat'],
                    'dest_lng' => $target['lng'],
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
}
