<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Models\TripLocation;
use App\Models\Driver;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log; // WAJIB ADA INI AGAR TIDAK ERROR 500

class TripController extends Controller
{
    /**
     * Driver Memulai Perjalanan
     */
    public function startTrip(Request $request)
    {
        try {
            $user = $request->user();
            $driver = Driver::where('user_id', $user->id)->first();

            if (!$driver) {
                return response()->json([
                    'message' => 'Profil Driver tidak ditemukan.'
                ], 404);
            }

            $trip = Trip::create([
                'driver_id' => $driver->id,
                'angkot_id' => $driver->angkot_id,
                'start_time' => now(),
                'status' => 'ongoing',
                'current_status' => 'green',
                'current_eta' => 0
            ]);

            return response()->json($trip);
        } catch (\Exception $e) {
            Log::error("Start Trip Error: " . $e->getMessage());
            return response()->json(['message' => 'Gagal membuat data perjalanan.'], 500);
        }
    }

    /**
     * Update Lokasi Real-time oleh Driver
     */
    public function updateLocation(Request $request, $id)
    {
        try {
            $request->validate([
                'latitude' => 'required',
                'longitude' => 'required',
                'speed' => 'nullable'
            ]);

            TripLocation::create([
                'trip_id' => $id,
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'speed' => $request->speed ?? 0
            ]);

            return response()->json(['status' => 'success']);
        } catch (\Exception $e) {
            Log::error("Update Location Error: " . $e->getMessage());
            return response()->json(['message' => 'Gagal update lokasi.'], 500);
        }
    }

    /**
     * Mendapatkan Daftar Angkot Aktif (UNTUK USER/GUEST)
     * Gabungan Method yang sudah diperkuat
     */
    public function getActiveAngkots()
    {
        try {
            // Eager loading relasi untuk performa dan menghindari N+1 query
            $trips = Trip::with(['angkot.route', 'driver.user'])
                ->where('status', 'ongoing')
                ->get();

            $data = $trips->map(function ($trip) {
                // Ambil koordinat terakhir
                $latestLocation = TripLocation::where('trip_id', $trip->id)
                    ->latest()
                    ->first();

                // Null-Safety: Memastikan jika data relasi corrupt, API tidak mati
                return [
                    'trip_id'       => $trip->id,
                    'angkot_number' => $trip->angkot->angkot_number ?? 'N/A',
                    'route_name'    => ($trip->angkot && $trip->angkot->route) ? $trip->angkot->route->name : 'Rute Medan',
                    'driver_name'   => ($trip->driver && $trip->driver->user) ? $trip->driver->user->name : 'Driver',
                    'latitude'      => $latestLocation ? (float)$latestLocation->latitude : 3.5952,
                    'longitude'     => $latestLocation ? (float)$latestLocation->longitude : 98.6722,
                    'speed'         => $latestLocation ? (float)$latestLocation->speed : 0,
                    'eta_minutes'   => rand(5, 15),
                    'crowd_status'  => 'Normal',
                    'congestion'    => $trip->current_status ?? 'green',
                ];
            });

            return response()->json($data);

        } catch (\Exception $e) {
            Log::error("Get Active Angkots Error: " . $e->getMessage());
            return response()->json([
                'message' => 'Internal Server Error',
                'debug' => $e->getMessage()
            ], 500);
        }
    }
}
