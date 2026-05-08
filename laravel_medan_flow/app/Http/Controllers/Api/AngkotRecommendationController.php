<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\AngkotRecommendationService;
use Illuminate\Http\Request;

class AngkotRecommendationController extends Controller
{
    private AngkotRecommendationService $service;

    public function __construct(AngkotRecommendationService $service)
    {
        $this->service = $service;
    }

    /**
     * GET /api/angkot/recommend?asal=Padang Bulan&tujuan=Amplas
     * POST /api/angkot/recommend { asal, tujuan }
     */
    public function recommend(Request $request)
    {
        $asal   = $request->input('asal', '');
        $tujuan = $request->input('tujuan', '');

        if (empty($tujuan)) {
            return response()->json([
                'error' => 'Parameter tujuan wajib diisi.'
            ], 422);
        }

        // Jika ada asal & tujuan → cari langsung + transit
        // Jika hanya tujuan → cari semua angkot yang ke tujuan
        if (!empty($asal)) {
            $result = $this->service->recommend($asal, $tujuan);
        } else {
            $result = $this->service->recommendByDestination($tujuan);
        }

        return response()->json($result);
    }

    /**
     * GET /api/angkot/search?q=Amplas
     * Cari semua trayek yang melewati keyword
     */
    public function search(Request $request)
    {
        $query = $request->input('q', '');

        if (strlen($query) < 2) {
            return response()->json(['results' => [], 'total' => 0]);
        }

        $result = $this->service->recommendByDestination($query);

        return response()->json([
            'results' => $result['rekomendasi'],
            'total'   => $result['total'],
        ]);
    }
}
