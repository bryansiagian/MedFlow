<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AngkotRecommendationService
{
    /**
     * Rekomendasikan angkot berdasarkan keyword asal & tujuan
     *
     * @param string $asalKeyword   e.g. "Padang Bulan"
     * @param string $tujuanKeyword e.g. "Amplas"
     * @return array
     */
    public function recommend(string $asalKeyword, string $tujuanKeyword): array
    {
        $allRoutes = DB::table('angkot_routes')->get();

        $langsung = [];
        $transit  = [];

        // ── 1. Cari angkot LANGSUNG ──────────────────────────────────────
        // Trayek yang rute_lengkap-nya mengandung KEDUA keyword
        foreach ($allRoutes as $route) {
            $rute = Str::lower($route->rute_lengkap);
            $asal = Str::lower($asalKeyword);
            $tuju = Str::lower($tujuanKeyword);

            $coverAsal  = Str::contains($rute, $asal)  || Str::contains(Str::lower($route->asal), $asal);
            $coverTujuan= Str::contains($rute, $tuju)  || Str::contains(Str::lower($route->tujuan), $tuju);

            if ($coverAsal && $coverTujuan) {
                $langsung[] = $this->formatRoute($route, 'langsung');
            }
        }

        // ── 2. Cari angkot TRANSIT (jika langsung < 2) ───────────────────
        // Cari trayek dari asal → titik tengah
        // lalu trayek dari titik tengah → tujuan
        if (count($langsung) < 2) {
            $dariAsal   = $this->getRoutesContaining($allRoutes, $asalKeyword);
            $keTujuan   = $this->getRoutesContaining($allRoutes, $tujuanKeyword);

            foreach ($dariAsal as $r1) {
                foreach ($keTujuan as $r2) {
                    if ($r1->id === $r2->id) continue;

                    // Cari titik persimpangan (jalan yang sama)
                    $titikTemu = $this->findTransferPoint($r1->rute_lengkap, $r2->rute_lengkap);

                    if ($titikTemu) {
                        $transit[] = [
                            'type'        => 'transit',
                            'kali_naik'   => 2,
                            'titik_transfer' => $titikTemu,
                            'angkot_1'    => $this->formatRoute($r1, 'transit_1'),
                            'angkot_2'    => $this->formatRoute($r2, 'transit_2'),
                            'instruksi'   => "Naik {$r1->perusahaan} {$r1->kode} → turun di {$titikTemu} → naik {$r2->perusahaan} {$r2->kode}",
                        ];

                        // Batasi hasil transit agar tidak terlalu banyak
                        if (count($transit) >= 3) break 2;
                    }
                }
            }
        }

        return [
            'asal'          => $asalKeyword,
            'tujuan'        => $tujuanKeyword,
            'langsung'      => $langsung,
            'transit'       => array_values($transit),
            'total_langsung'=> count($langsung),
            'total_transit' => count($transit),
            'ada_rekomendasi'=> count($langsung) > 0 || count($transit) > 0,
        ];
    }

    /**
     * Rekomendasikan berdasarkan keyword tujuan saja
     * (user tidak tahu nama daerah asalnya)
     */
    public function recommendByDestination(string $tujuanKeyword): array
    {
        $allRoutes = DB::table('angkot_routes')->get();
        $hasil = [];

        foreach ($allRoutes as $route) {
            $rute = Str::lower($route->rute_lengkap);
            $tuju = Str::lower($tujuanKeyword);

            if (Str::contains($rute, $tuju) || Str::contains(Str::lower($route->tujuan), $tuju)) {
                $hasil[] = $this->formatRoute($route, 'langsung');
            }
        }

        return [
            'tujuan'         => $tujuanKeyword,
            'rekomendasi'    => $hasil,
            'total'          => count($hasil),
            'ada_rekomendasi'=> count($hasil) > 0,
        ];
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private function getRoutesContaining($routes, string $keyword): array
    {
        $kw = Str::lower($keyword);
        return $routes->filter(function ($r) use ($kw) {
            return Str::contains(Str::lower($r->rute_lengkap), $kw)
                || Str::contains(Str::lower($r->asal), $kw)
                || Str::contains(Str::lower($r->tujuan), $kw);
        })->values()->all();
    }

    private function findTransferPoint(string $rute1, string $rute2): ?string
    {
        // Pecah rute menjadi titik-titik pemberhentian
        $titik1 = array_map('trim', explode('–', $rute1));
        $titik2 = array_map('trim', explode('–', $rute2));

        // Normalisasi
        $titik1Lower = array_map(fn($t) => Str::lower($t), $titik1);
        $titik2Lower = array_map(fn($t) => Str::lower($t), $titik2);

        // Cari titik yang sama (partial match)
        foreach ($titik1 as $i => $t1) {
            foreach ($titik2 as $j => $t2) {
                $t1l = $titik1Lower[$i];
                $t2l = $titik2Lower[$j];

                // Minimal 6 karakter cocok
                if (strlen($t1l) >= 6 && (Str::contains($t1l, $t2l) || Str::contains($t2l, $t1l))) {
                    return $t1; // kembalikan versi asli
                }
            }
        }

        return null;
    }

    private function formatRoute($route, string $type): array
    {
        return [
            'type'        => $type,
            'kode'        => $route->kode,
            'perusahaan'  => $route->perusahaan,
            'warna'       => $route->warna,
            'asal'        => $route->asal,
            'tujuan'      => $route->tujuan,
            'rute_lengkap'=> $route->rute_lengkap,
            'pp'          => $route->pp,
            'warna_hex'   => $this->warnaToHex($route->warna),
            'label'       => "{$route->perusahaan} {$route->kode}",
        ];
    }

    private function warnaToHex(string $warna): string
    {
        return match(Str::lower($warna)) {
            'kuning'      => '#F59E0B',
            'merah'       => '#DC2626',
            'merah hijau' => '#16A34A',
            'biru'        => '#2563EB',
            'hijau'       => '#16A34A',
            'putih'       => '#6B7280',
            default       => '#6B7280',
        };
    }
}
