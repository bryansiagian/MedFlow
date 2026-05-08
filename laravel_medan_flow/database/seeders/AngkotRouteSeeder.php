<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AngkotRouteSeeder extends Seeder
{
    public function run(): void
    {
        $routes = [
            // ── KPUM (Kuning) ────────────────────────────────────────────
            ['kode'=>'01',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Simp. Permina',        'tujuan'=>'Lubuk Pakam',          'rute_lengkap'=>'Simp. Permina – Tanjung Morawa – Simp. Kayu Besar – Lubuk Pakam'],
            ['kode'=>'02',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Jl. Karya',            'tujuan'=>'Perumnas Mandala',      'rute_lengkap'=>'Jl. Karya – Bundaran Sekip – Petisah – Plaza Medan Fair – Jl. Iskandar Muda – Simp. Brimob – Simp. Kampus – Padang Bulan – Simp. Pos – Titi Kuning – Simp. Limun – Jl. Sisingamangaraja – Jl. Halat – Jl. AR Hakim – Jl. Denai – Perumnas Mandala'],
            ['kode'=>'03',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'POLDASU',              'tujuan'=>'Sambu',                 'rute_lengkap'=>'POLDASU – Amplas – Jl. Sisingamangaraja – Garuda Plaza Hotel – Sambu'],
            ['kode'=>'A03', 'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'UNIMED',               'tujuan'=>'Pasar V Martoba',       'rute_lengkap'=>'UNIMED – Jl. Pancing – Aksara – Pasar V Desa Martoba / Batas Kota'],
            ['kode'=>'N03', 'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Tuntungan',            'tujuan'=>'Lubuk Pakam',           'rute_lengkap'=>'Tuntungan – Lau Bakeri – Tanjung Anom – Pajak Melati – Simp. Pemda – Simp. Pos – Titi Kuning – Amplas – Tanjung Morawa – Lubuk Pakam'],
            ['kode'=>'05',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Jl. SM. Raja',        'tujuan'=>'Mariendal',             'rute_lengkap'=>'Jalan SM. Raja – Mariendal – PP'],
            ['kode'=>'06',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Pinang Baris',         'tujuan'=>'Amplas',                'rute_lengkap'=>'Pinang Baris – Pajak Melati – Simp. Pemda – Tanjung Sari – TASBI Pintu 1 – Jl. Dr. Mansyur – USU – Simp. Kampus – Simp. Brimob – Jl. S. Parman – Jl. Monginsidi – Jl. Ir. H. Juanda – Jl. Sisingamangaraja – Amplas'],
            ['kode'=>'07',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Terminal Amplas',      'tujuan'=>'Tembung',               'rute_lengkap'=>'Terminal Amplas – Jl. Sisingamangaraja – Teladan – Aksara – Jl. Pancing – Letda Sujono / Batas Kota – Tembung'],
            ['kode'=>'08',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Jl. Palang Merah',    'tujuan'=>'Deli Tua',              'rute_lengkap'=>'Jl. Palang Merah – B. Katamso – Istana Maimun – Pancing – Titi Kuning – Deli Tua'],
            ['kode'=>'10',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Perumnas Simalingkar', 'tujuan'=>'Aksara',                'rute_lengkap'=>'Perumnas Simalingkar – Simp. Pos – Padang Bulan – Simp. Kampus – Simp. Brimob – Pringgan – Jl. Hayam Wuruk – Jl. S. Parman – Jl. Jend. Sudirman – Taman Beringin – Kantor Gubernur – Sun Plaza – Simp. Selecta – Jl. Palang Merah – Jl. Sutomo – Sambu – Aksara'],
            ['kode'=>'11',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Perumnas Simalingkar', 'tujuan'=>'Pancing',               'rute_lengkap'=>'Jalan P. Simalingkar – Pd. Bulan – Pringgan – Lap. Merdeka – Pancing / Batas Kota'],
            ['kode'=>'13',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Tuntungan',            'tujuan'=>'RS Mina / UMA',         'rute_lengkap'=>'Jalan Tuntungan / Bts Kota – Rs. Mina / UMA'],
            ['kode'=>'14',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Tembung',              'tujuan'=>'Tj. Selamat',           'rute_lengkap'=>'Jalan Tembung – Tj. Selamat / Batas Kota'],
            ['kode'=>'17',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Karya Jasa',           'tujuan'=>'Belawan',               'rute_lengkap'=>'Jalan Karya Jasa / B. Kota – Belawan'],
            ['kode'=>'18',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Tj. Selamat',          'tujuan'=>'P. Mandala',            'rute_lengkap'=>'Jalan Tj. Selamat / Bts Kota – P. Mandala'],
            ['kode'=>'23',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'T. Pinang Baris',      'tujuan'=>'B. Katamso',            'rute_lengkap'=>'Jalan T. Pinang Baris – B. Katamso / Bts Kota'],
            ['kode'=>'27',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Metrologi',            'tujuan'=>'Marendal',              'rute_lengkap'=>'Jalan Metrologi – Marendal / Batas Kota'],
            ['kode'=>'28',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Letda Sujono',         'tujuan'=>'Gabion',                'rute_lengkap'=>'Jalan Letda Sujono / Bts Kota – Gabion'],
            ['kode'=>'33',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Tuntungan',            'tujuan'=>'R. Potong',             'rute_lengkap'=>'Jalan Tuntungan / Batas Kota – R. Potong'],
            ['kode'=>'35',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Tb. Sihombing',        'tujuan'=>'T. Pinang Baris',       'rute_lengkap'=>'Jalan Tb. Sihombing / Bts Kota – T. Pinang Baris'],
            ['kode'=>'37',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Johor / Pasar V',      'tujuan'=>'T. Belawan',            'rute_lengkap'=>'Jalan Johor / Pasar V / Bts Kota – T. Belawan'],
            ['kode'=>'38',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Rs. Adam Malik',       'tujuan'=>'Desa Martoba',          'rute_lengkap'=>'Jalan Rs. Adam Malik – Desa Martoba / Bts Kota'],
            ['kode'=>'39',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'T. P. Baris',          'tujuan'=>'SMU XI / Pertiwi',      'rute_lengkap'=>'Jalan T. P. Baris – Pertiwi / SMU XI / Bts Kota'],
            ['kode'=>'40',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Kelambir Lima',        'tujuan'=>'P. Mandala',            'rute_lengkap'=>'Jalan Kelambir Lima / Bts Kota – P. Mandala'],
            ['kode'=>'42',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Johor',                'tujuan'=>'Pasar VII',             'rute_lengkap'=>'Jalan Johor – STM – S. Limun – Pasar VII'],
            ['kode'=>'45',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Desa Simalingkar B',   'tujuan'=>'Letda Sujono',          'rute_lengkap'=>'Jalan Desa Simalingkar B – Letda Sujono / Bts Kota'],
            ['kode'=>'46',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Tj. Selamat',          'tujuan'=>'Tembung',               'rute_lengkap'=>'Jalan Tj. Selamat – Sei Serayu – Jl. Darusalam – Gatot Subroto – Berastagi Swalayan – Letda Sujono – Tembung'],
            ['kode'=>'47',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'T. Pinang Baris',      'tujuan'=>'Letda Sujono',          'rute_lengkap'=>'Jalan T. Pinang Baris – Letda Sujono / Bts Kota'],
            ['kode'=>'50',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'T. Pinang Baris',      'tujuan'=>'Jermal XI',             'rute_lengkap'=>'Jalan T. Pinang Baris – Jermal XI / Bts Kota'],
            ['kode'=>'51',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'T. Pinang Baris',      'tujuan'=>'Desa Jambu',            'rute_lengkap'=>'Jalan T. Pinang Baris – Desa Jambu / Bts Kota'],
            ['kode'=>'52',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Padang Bulan',         'tujuan'=>'Pinang Baris',          'rute_lengkap'=>'Jalan Padang Bulan – Titi Kuning – Pringgan – Pinang Baris'],
            ['kode'=>'54',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Pasar VII Tj. M. Hilir','tujuan'=>'Tuntungan',            'rute_lengkap'=>'Jalan Pasar VII Tj. M. Hilir – Tuntungan / Bts Kota'],
            ['kode'=>'55',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'T. Amplas',            'tujuan'=>'Letda Sujono',          'rute_lengkap'=>'Jalan T. Amplas – Letda Sujono / Bts Kota'],
            ['kode'=>'56',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Tj. Selamat',          'tujuan'=>'Lau Dendang',           'rute_lengkap'=>'Jalan Tj. Selamat – Lau Dendang / Bts Kota'],
            ['kode'=>'57',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Tj. Selamat',          'tujuan'=>'P. Mandala',            'rute_lengkap'=>'Jalan Tj. Selamat / Bts Kota – P. Mandala'],
            ['kode'=>'59',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'P. Mandala',           'tujuan'=>'B. Katamso',            'rute_lengkap'=>'Jalan P. Mandala – B. Katamso / Bts Kota'],
            ['kode'=>'60',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'P. Simalingkar',       'tujuan'=>'Martoba',               'rute_lengkap'=>'Jalan P. Simalingkar Martoba / Bts Kota'],
            ['kode'=>'64',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Amplas',               'tujuan'=>'Pringgan',              'rute_lengkap'=>'Jalan Amplas – Sp. Limun – Sun Plaza – Pringgan'],
            ['kode'=>'65',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Kelambir V',           'tujuan'=>'T. Pinang Baris',       'rute_lengkap'=>'Jalan Kelambir V / Bts Kota – T. Pinang Baris'],
            ['kode'=>'68',  'perusahaan'=>'KPUM', 'warna'=>'Kuning', 'asal'=>'Kelambir V',           'tujuan'=>'Kelambir V',            'rute_lengkap'=>'Jalan Kelambir V / Bts Kota'],
            ['kode'=>'A97', 'perusahaan'=>'KPUM', 'warna'=>'Merah',  'asal'=>'Pancur Batu',          'tujuan'=>'Lubuk Pakam',           'rute_lengkap'=>'Pancur Batu – Amplas – T. Morawa – Lubuk Pakam'],

            // ── RMC / Rahayu Medan Ceria (Merah Hijau) ──────────────────
            ['kode'=>'41',  'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'Tembung',         'tujuan'=>'RSU Adam Malik',        'rute_lengkap'=>'Jalan Tembung / Bts Kota – Jl. HM Yamin – Jl. Amaliun – Yuki Simpang Raya – Jl. Juanda – Monginsidi – USU – Padang Bulan – RSU Adam Malik'],
            ['kode'=>'42',  'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'RSU Adam Malik',  'tujuan'=>'Medan Estate',          'rute_lengkap'=>'Jalan RSU Adam Malik – Pringgan – Komp. IKIP / Medan Estate / Bts Kota'],
            ['kode'=>'43',  'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'P. Simalingkar',  'tujuan'=>'P. Mandala',            'rute_lengkap'=>'Jalan P. Simalingkar / Bts Kota – P. Mandala / Bts Kota'],
            ['kode'=>'54',  'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'Simalingkar',     'tujuan'=>'Medan Estate',          'rute_lengkap'=>'Jalan Desa Simalingkar – Kebun Binatang Simalingkar – USU – Pringgan – Komp. IKIP / Medan Estate'],
            ['kode'=>'58',  'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'Tj. Anom',        'tujuan'=>'Tembung',               'rute_lengkap'=>'Jalan Tj. Anom / Bts Kota – Tembung / Bts Kota'],
            ['kode'=>'103', 'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'IKIP / Medan Estate','tujuan'=>'Pancur Batu',        'rute_lengkap'=>'Jalan IKIP / Medan Estate – Pancur Batu'],
            ['kode'=>'104', 'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'Padang Bulan',    'tujuan'=>'UNIMED',                'rute_lengkap'=>'Jalan Pd. Bulan – Pringgan – Aksara – UNIMED'],
            ['kode'=>'105', 'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'Terminal Amplas', 'tujuan'=>'Komplek Uka Terjun',    'rute_lengkap'=>'Jalan Terminal Amplas – Marelan – Pancing – Aksara – Komplek Uka Terjun'],
            ['kode'=>'106', 'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'Terminal Amplas', 'tujuan'=>'Perumnas Mandala',      'rute_lengkap'=>'Jalan Terminal Amplas – Perumnas Mandala'],
            ['kode'=>'107', 'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'Pancur Batu',     'tujuan'=>'Perumnas Mandala',      'rute_lengkap'=>'Jalan Pancur Batu – Perumnas Mandala'],
            ['kode'=>'120', 'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'T. Pinang Baris', 'tujuan'=>'Amplas',                'rute_lengkap'=>'Jalan T. Pinang Baris – Setia Budi – USU – Pd. Bulan – Titi Kuning – Amplas'],
            ['kode'=>'125', 'perusahaan'=>'RMC',  'warna'=>'Merah Hijau', 'asal'=>'Medan Amplas',    'tujuan'=>'Medan Labuhan',         'rute_lengkap'=>'Jalan Medan Amplas – Martubung – Medan Labuhan'],

            // ── Medan Bus (Biru) ─────────────────────────────────────────
            ['kode'=>'11',  'perusahaan'=>'Medan Bus', 'warna'=>'Biru', 'asal'=>'T. Morawa',         'tujuan'=>'Belawan / Gabion',      'rute_lengkap'=>'Jalan T. Morawa / Bts Kota – Belawan – Gabion'],
            ['kode'=>'36',  'perusahaan'=>'Medan Bus', 'warna'=>'Biru', 'asal'=>'Karya Wisata',      'tujuan'=>'Tembung',               'rute_lengkap'=>'Jalan Karya Wisata – Tembung / Bts Kota'],
            ['kode'=>'45',  'perusahaan'=>'Medan Bus', 'warna'=>'Biru', 'asal'=>'T. P. Baris',       'tujuan'=>'Tembung',               'rute_lengkap'=>'Jalan T. P. Baris – Tembung / Bts Kota'],
            ['kode'=>'47',  'perusahaan'=>'Medan Bus', 'warna'=>'Biru', 'asal'=>'T. P. Baris',       'tujuan'=>'P. Mandala',            'rute_lengkap'=>'Jalan T. P. Baris – P. Mandala / Bts Kota'],
            ['kode'=>'56',  'perusahaan'=>'Medan Bus', 'warna'=>'Biru', 'asal'=>'Tj. Morawa',        'tujuan'=>'Belawan / Gabion',      'rute_lengkap'=>'Jalan Tj. Morawa / Bts Kota – Belawan – Gabion'],
            ['kode'=>'135', 'perusahaan'=>'Medan Bus', 'warna'=>'Biru', 'asal'=>'Amplas',            'tujuan'=>'Helvetia',              'rute_lengkap'=>'Jalan Amplas – Pd. Bulan – USU – Helvetia'],

            // ── Nasional Medan Transport (Biru) ──────────────────────────
            ['kode'=>'K04', 'perusahaan'=>'Nasional', 'warna'=>'Biru', 'asal'=>'P. Simalingkar',     'tujuan'=>'Sp. Bw / Bts Kota',    'rute_lengkap'=>'Jalan P. Simalingkar – Sp. Bw / Bts Kota'],
            ['kode'=>'25',  'perusahaan'=>'Nasional', 'warna'=>'Biru', 'asal'=>'Tj. Selamat',        'tujuan'=>'Veteran / P. Psr',      'rute_lengkap'=>'Jalan Tj. Selamat / Bts Kota – Veteran / P. Psr'],
            ['kode'=>'M27', 'perusahaan'=>'Nasional', 'warna'=>'Biru', 'asal'=>'T. Morawa',          'tujuan'=>'Tj. Selamat',           'rute_lengkap'=>'Jalan T. Morawa / Bts Kota – Tj. Selamat / Bts Kota'],
            ['kode'=>'M28', 'perusahaan'=>'Nasional', 'warna'=>'Biru', 'asal'=>'P. III Simalingkar', 'tujuan'=>'Veteran / P. Psr',      'rute_lengkap'=>'Jalan P. III Simalingkar – Jl. R. Saleh – Veteran / P. Psr'],
            ['kode'=>'M29', 'perusahaan'=>'Nasional', 'warna'=>'Biru', 'asal'=>'Sp. Selayang',       'tujuan'=>'Letda Sujono',          'rute_lengkap'=>'Jalan Sp. Selayang – Letda Sujono / Bts Kota'],

            // ── Morina (Hijau) ────────────────────────────────────────────
            ['kode'=>'75',  'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'IKIP / UNIMED',       'tujuan'=>'Bagan Deli',            'rute_lengkap'=>'Jalan Batas Kota / IKIP UNIMED – Bagan Deli'],
            ['kode'=>'80',  'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'Perumnas Martubung',  'tujuan'=>'Tj. Selamat',           'rute_lengkap'=>'Jalan Perumnas Martubung – Jl. Sunggal – Tj. Selamat / Bts Kota'],
            ['kode'=>'81',  'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'Amplas',              'tujuan'=>'Belawan',               'rute_lengkap'=>'Jalan Amplas – Belawan'],
            ['kode'=>'139', 'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'Letda Sujono',        'tujuan'=>'Terminal Belawan',      'rute_lengkap'=>'Jalan Letda Sujono / Batas Kota – Terminal Belawan'],
            ['kode'=>'140', 'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'T. Pinang Baris',     'tujuan'=>'Letda Sujono',          'rute_lengkap'=>'Jalan Terminal Pinang Baris – Letda Sujono / Bts Kota'],
            ['kode'=>'141', 'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'Pancur Batu',         'tujuan'=>'P. Mandala',            'rute_lengkap'=>'Jalan Pancur Batu / Bts Kota – P. Mandala / Bts Kota'],
            ['kode'=>'142', 'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'Pancur Batu',         'tujuan'=>'Gabion Belawan',        'rute_lengkap'=>'Jalan Pancur Batu / Bts Kota – Gabion Belawan'],
            ['kode'=>'143', 'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'Tembung',             'tujuan'=>'Tj. Anom',              'rute_lengkap'=>'Jalan Tembung Psr X / Bts Kota – Tj. Anom / Bts Kota'],
            ['kode'=>'144', 'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'Desa Martoba',        'tujuan'=>'Kelambir V',            'rute_lengkap'=>'Jalan Desa Martoba / Desa Kelambir V / Bts Kota'],
            ['kode'=>'145', 'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'Tj. Anom',            'tujuan'=>'Tembung',               'rute_lengkap'=>'Jalan Tj. Anom / Bts Kota – Tembung Psr X / Bts Kota'],
            ['kode'=>'146', 'perusahaan'=>'Morina', 'warna'=>'Hijau', 'asal'=>'RSU Adam Malik',      'tujuan'=>'Hamparan Perak',        'rute_lengkap'=>'Jalan RSU Adam Malik – Hamparan Perak / Bts Kota'],

            // ── Mars (Hijau) ──────────────────────────────────────────────
            ['kode'=>'13',  'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'P. Mandala',           'tujuan'=>'Tj. Gusta Sukadono',    'rute_lengkap'=>'Jalan P. Mandala / Batas Kota – Tj. Gusta Sukadono'],
            ['kode'=>'60',  'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'Aksara',               'tujuan'=>'Pasar I',               'rute_lengkap'=>'Jalan Aksara – Hayam Wuruk – Pd. Bulan – Pasar I'],
            ['kode'=>'61',  'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'Simalingkar',          'tujuan'=>'Belawan',               'rute_lengkap'=>'Jalan Simalingkar – Pd. Bulan – Belawan'],
            ['kode'=>'65',  'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'Tembung',              'tujuan'=>'Bagan Deli / Belawan',  'rute_lengkap'=>'Jalan Tembung / Batas Kota – Bagan Deli / Belawan'],
            ['kode'=>'70',  'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'P. Mandala',           'tujuan'=>'T. P. Baris',           'rute_lengkap'=>'Jalan P. Mandala / Batas Kota – T. P. Baris'],
            ['kode'=>'71',  'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'Tj. Gusta',            'tujuan'=>'Tembung',               'rute_lengkap'=>'Jalan Tj. Gusta – Tembung / Batas Kota'],
            ['kode'=>'45',  'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'B. Katamso',           'tujuan'=>'Pasar V',               'rute_lengkap'=>'Jalan B. Katamso / Batas Kota – Pasar V / Batas Kota'],
            ['kode'=>'128', 'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'Letda Sujono',         'tujuan'=>'Belawan / Gabion',      'rute_lengkap'=>'Jalan Letda Sujono / Batas Kota – Belawan / Gabion'],
            ['kode'=>'129', 'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'B. Katamso',           'tujuan'=>'Belawan / Gabion',      'rute_lengkap'=>'Jalan B. Katamso / Bts Kota – Belawan / Gabion'],
            ['kode'=>'130', 'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'Tj. Selamat',          'tujuan'=>'Belawan / Gabion',      'rute_lengkap'=>'Jalan Tj. Selamat / Bts Kota – Belawan / Gabion'],
            ['kode'=>'131', 'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'Jamin Ginting',        'tujuan'=>'Gabion',                'rute_lengkap'=>'Jalan Jamin Ginting / Bts Kota – Gabion'],
            ['kode'=>'133', 'perusahaan'=>'Mars',  'warna'=>'Hijau', 'asal'=>'Tj. Selamat',          'tujuan'=>'P. Pasar',              'rute_lengkap'=>'Jalan Tj. Selamat / Bts Kota – P. Pasar / Bts Kota'],

            // ── Mekar Jaya (Kuning) ───────────────────────────────────────
            ['kode'=>'116', 'perusahaan'=>'Mekar Jaya', 'warna'=>'Kuning', 'asal'=>'Pasar V',        'tujuan'=>'Terjun',                'rute_lengkap'=>'Jalan Pasar V / Batas Kota – Terjun / Batas Kota'],

            // ── Hikma ─────────────────────────────────────────────────────
            ['kode'=>'26',  'perusahaan'=>'Hikma', 'warna'=>'Putih', 'asal'=>'Desa Terjun',          'tujuan'=>'T. Amplas',             'rute_lengkap'=>'Jalan Desa Terjun / Bts Kota – T. Amplas'],
            ['kode'=>'62',  'perusahaan'=>'Hikma', 'warna'=>'Putih', 'asal'=>'T. Amplas',            'tujuan'=>'Desa Terjun',           'rute_lengkap'=>'Jalan T. Amplas – Desa Terjun / Bts Kota'],
            ['kode'=>'63',  'perusahaan'=>'Hikma', 'warna'=>'Putih', 'asal'=>'T. Belawan',           'tujuan'=>'Pancur Batu',           'rute_lengkap'=>'Jalan T. Belawan – P. Batu / Bts Kota'],

            // ── Kobun ─────────────────────────────────────────────────────
            ['kode'=>'62',  'perusahaan'=>'Kobun', 'warna'=>'Kuning', 'asal'=>'Tuntungan',           'tujuan'=>'T. Amplas',             'rute_lengkap'=>'Jalan Tuntungan / Bts Kota – T. Amplas'],
            ['kode'=>'63',  'perusahaan'=>'Kobun', 'warna'=>'Kuning', 'asal'=>'Kedai Durian',        'tujuan'=>'T. P. Baris',           'rute_lengkap'=>'Jalan Kedai Durian / Bts Kota – T. P. Baris'],

            // ── POVRI ─────────────────────────────────────────────────────
            ['kode'=>'04',  'perusahaan'=>'POVRI', 'warna'=>'Putih', 'asal'=>'Perum Indah / Eka Rasmi','tujuan'=>'IKIP Baru',           'rute_lengkap'=>'Jalan Perum Indah / Eka Rasmi – IKIP Baru / Bts Kota'],
            ['kode'=>'05',  'perusahaan'=>'POVRI', 'warna'=>'Putih', 'asal'=>'Deli Tua',             'tujuan'=>'Veteran / P. Psr',      'rute_lengkap'=>'Jalan Deli Tua / Bts Kota – Veteran / P. Psr'],
        ];

        // Tambahkan timestamps
        $now = now();
        $data = array_map(fn($r) => array_merge($r, [
            'pp'         => true,
            'created_at' => $now,
            'updated_at' => $now,
        ]), $routes);

        DB::table('angkot_routes')->insert($data);

        $this->command->info('✅ ' . count($data) . ' trayek angkot Medan berhasil di-seed!');
    }
}
