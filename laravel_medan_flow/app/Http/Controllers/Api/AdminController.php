<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Angkot;
use App\Models\Trip;
use App\Models\TrafficData;
use App\Models\User;
use App\Models\Driver;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class AdminController extends Controller
{
    public function getDashboardStats()
    {
        try {
            // Angkot yang sedang aktif menarik (trip berstatus ongoing)
            $activeAngkots = Trip::where('status', 'ongoing')
                ->distinct('angkot_id')
                ->count('angkot_id') ?? 0;

            // Total driver terdaftar
            $totalDrivers = User::where('role_id', 2)->count() ?? 0;

            // Congestion index dari data trafik terbaru (opsional, fallback ke hardcoded)
            $latestTraffic = TrafficData::latest()->first();
            $congestionIndex = $latestTraffic
                ? $latestTraffic->congestion_index . '%'
                : '42%';

            // Data mingguan untuk grafik
            $chart_data = [
                ['day' => 'Sen', 'value' => 45],
                ['day' => 'Sel', 'value' => 52],
                ['day' => 'Rab', 'value' => 38],
                ['day' => 'Kam', 'value' => 65],
                ['day' => 'Jum', 'value' => 82],
                ['day' => 'Sab', 'value' => 40],
                ['day' => 'Min', 'value' => 30],
            ];

            return response()->json([
                'status' => 'success',
                'overview' => [
                    'active_angkots'   => $activeAngkots,
                    'total_drivers'    => $totalDrivers,
                    'congestion_index' => $congestionIndex,
                ],
                'chart_data' => $chart_data,
                'recent_incidents' => [
                    ['loc' => 'Jl. Thamrin',  'status' => 'Macet Parah',    'time' => '10 mnt lalu'],
                    ['loc' => 'Simpang Pos',  'status' => 'Padat Merayap',  'time' => '15 mnt lalu'],
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Admin Stats Error: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => 'Internal Server Error: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function getPendingDrivers()
    {
        try {
            $pending = Driver::with(['user', 'angkot.route'])
                ->where('status', 'pending')
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json($pending);

        } catch (\Exception $e) {
            Log::error('Get Pending Drivers Error: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => 'Internal Server Error: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function approveDriver(Request $request, $id)
    {
        try {
            $driver = Driver::findOrFail($id);
            $driver->update(['status' => 'active']);

            return response()->json([
                'status'  => 'success',
                'message' => 'Driver ' . $driver->user->name . ' telah disetujui dan sekarang dapat menarik angkot.',
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Driver tidak ditemukan.',
            ], 404);

        } catch (\Exception $e) {
            Log::error('Approve Driver Error: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => 'Internal Server Error: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function rejectDriver(Request $request, $id)
    {
        try {
            $driver = Driver::findOrFail($id);
            $userName = $driver->user->name;

            // Menghapus user otomatis menghapus driver (cascade delete)
            $driver->user->delete();

            return response()->json([
                'status'  => 'success',
                'message' => 'Pendaftaran Driver ' . $userName . ' telah ditolak dan dihapus.',
            ]);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Driver tidak ditemukan.',
            ], 404);

        } catch (\Exception $e) {
            Log::error('Reject Driver Error: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => 'Internal Server Error: ' . $e->getMessage(),
            ], 500);
        }
    }
}
