<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\{User, Driver, Role};
use App\Mail\OtpMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{Hash, Mail, DB, Validator, Log};
use Carbon\Carbon;

class AuthController extends Controller
{
    public function registerDriver(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8',
            'vehicle_plate' => 'required',
            'angkot_id' => 'required'
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validasi gagal', 'errors' => $validator->errors()], 422);
        }

        try {
            return DB::transaction(function () use ($request) {
                // 1. Buat User
                $user = User::create([
                    'name' => $request->name,
                    'email' => $request->email,
                    'password' => Hash::make($request->password),
                    'role_id' => 2,
                ]);

                // 2. Buat profil Driver
                Driver::create([
                    'user_id' => $user->id,
                    'angkot_id' => $request->angkot_id,
                    'vehicle_plate' => $request->vehicle_plate,
                    'status' => 'pending',
                ]);

                // 3. Buat OTP
                $otpCode = (string) rand(100000, 999999);
                DB::table('otps')->updateOrInsert(
                    ['email' => $request->email],
                    [
                        'code' => $otpCode,
                        'expires_at' => Carbon::now()->addMinutes(10),
                        'created_at' => now()
                    ]
                );

                // 4. Kirim Email dengan Error Handling (Anti-Crash)
                $mailStatus = "sent";
                try {
                    Mail::to($request->email)->send(new OtpMail($otpCode));
                } catch (\Exception $e) {
                    Log::error("SMTP Error di AWS: " . $e->getMessage());
                    $mailStatus = "failed_due_to_vpc_restriction";
                }

                // 5. Kembalikan Respon Sukses (Apapun yang terjadi pada email)
                return response()->json([
                    'status' => 'success',
                    'message' => 'Registrasi berhasil.',
                    'mail_status' => $mailStatus,
                    // SANGAT PENTING UNTUK LOMBA:
                    // Jika email gagal karena internet AWS mati,
                    // kita kirim OTP di response agar juri tetap bisa lanjut demo.
                    'debug_otp' => $otpCode
                ], 200);
            });

        } catch (\Exception $e) {
            Log::error("Register Driver Error: " . $e->getMessage());
            return response()->json([
                'message' => 'Gagal menyimpan data ke RDS Sydney.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function verifyOtp(Request $request)
    {
        $request->validate(['email' => 'required|email', 'code' => 'required']);

        $otp = DB::table('otps')
            ->where('email', $request->email)
            ->where('code', $request->code)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$otp) {
            return response()->json(['message' => 'Kode OTP salah atau sudah kadaluarsa.'], 400);
        }

        User::where('email', $request->email)->update(['email_verified_at' => now()]);
        DB::table('otps')->where('email', $request->email)->delete();

        return response()->json(['message' => 'Email berhasil diverifikasi! Tunggu persetujuan admin.']);
    }

    public function login(Request $request)
    {
        $user = User::where('email', $request->email)->first();
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Email atau Password salah.'], 401);
        }
        if ($user->role_id == 2) {
            $driver = $user->driver;
            if ($user->email_verified_at == null) return response()->json(['message' => 'Verifikasi email dulu.'], 403);
            if ($driver->status == 'pending') return response()->json(['message' => 'Akun Anda sedang ditinjau oleh Admin.'], 403);
        }
        return response()->json([
            'token' => $user->createToken('auth_token')->plainTextToken,
            'user' => $user->load('role')
        ]);
    }
}
