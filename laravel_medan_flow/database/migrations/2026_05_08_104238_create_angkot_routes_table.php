<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('angkot_routes', function (Blueprint $table) {
            $table->id();
            $table->string('kode');           // e.g. "02", "A03", "RMC-103"
            $table->string('perusahaan');     // e.g. "KPUM", "RMC", "Morina"
            $table->string('warna');          // e.g. "Kuning", "Merah Hijau", "Biru"
            $table->string('asal');           // titik awal trayek
            $table->string('tujuan');         // titik akhir trayek
            $table->text('rute_lengkap');     // rute lengkap (semua jalan yang dilalui)
            $table->boolean('pp')->default(true); // pulang pergi
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('angkot_routes');
    }
};
