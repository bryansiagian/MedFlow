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
            $trips = Trip::with(['angkot.route', 'driver.user'])
                ->where('status', 'ongoing')
                ->whereHas('locations', function ($q) {
                    // Hanya tampilkan angkot yang update lokasi dalam 5 menit terakhir
                    $q->where('created_at', '>=', now()->subMinutes(5));
                })
                ->get();

            $data = $trips->map(function ($trip) {
                $latestLocation = TripLocation::where('trip_id', $trip->id)
                    ->latest()
                    ->first();

                // Skip angkot yang belum pernah kirim lokasi sama sekali
                if (!$latestLocation) return null;

                // Hitung crowd_status dari jumlah penumpang jika ada, fallback ke current_status
                $crowdStatus = match($trip->current_status ?? 'green') {
                    'red'    => 'Penuh',
                    'yellow' => 'Sedang',
                    default  => 'Normal',
                };

                // Hitung ETA berdasarkan speed (km/h) dan asumsi jarak rata-rata 2km
                $speed         = (float)($latestLocation->speed ?? 0);
                $estimatedEta  = ($speed > 5)
                    ? (int)round((2 / $speed) * 60)  // menit = (jarak/speed)*60
                    : rand(8, 20);                    // fallback jika angkot diam

                return [
                    'trip_id'       => $trip->id,
                    'angkot_number' => $trip->angkot->angkot_number ?? 'N/A',
                    'route_name'    => ($trip->angkot && $trip->angkot->route)
                                        ? $trip->angkot->route->name
                                        : 'Rute Medan',
                    'driver_name'   => ($trip->driver && $trip->driver->user)
                                        ? $trip->driver->user->name
                                        : 'Driver',
                    'latitude'      => (float)$latestLocation->latitude,
                    'longitude'     => (float)$latestLocation->longitude,
                    'speed'         => $speed,
                    'eta_minutes'   => $estimatedEta,
                    'crowd_status'  => $crowdStatus,
                    'congestion'    => $trip->current_status ?? 'green',
                    'last_updated'  => $latestLocation->created_at->toIso8601String(),
                ];
            })
            ->filter()   // Buang entry null (angkot tanpa lokasi)
            ->values();  // Re-index array agar JSON tidak jadi object

            return response()->json($data);

        } catch (\Exception $e) {
            Log::error("Get Active Angkots Error: " . $e->getMessage());
            return response()->json([
                'message' => 'Internal Server Error',
                'debug'   => env('APP_DEBUG') ? $e->getMessage() : 'Hubungi administrator.',
            ], 500);
        }
    }

    public function endTrip(Request $request, $id)
    {
        try {
            $trip = Trip::findOrFail($id);
            $trip->update(['status' => 'finished']); // ← ganti 'ended' jadi 'finished'
            return response()->json(['message' => 'Trip selesai.']);
        } catch (\Exception $e) {
            Log::error("End Trip Error: " . $e->getMessage());
            return response()->json(['message' => 'Gagal mengakhiri trip.'], 500);
        }
    }
}
