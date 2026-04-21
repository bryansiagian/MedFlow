<?php
namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiService
{
    private string $apiKey;
    private string $model = 'gemini-2.0-flash-lite';

    public function __construct()
    {
        $this->apiKey = env('GEMINI_API_KEY');
    }

    public function analyze(string $prompt): string
    {
        try {
            $url = "https://generativelanguage.googleapis.com/v1beta/models/{$this->model}:generateContent?key={$this->apiKey}";

            $response = Http::timeout(15)->post($url, [
                'contents' => [
                    ['parts' => [['text' => $prompt]]]
                ]
            ]);

            Log::info('Gemini Status: ' . $response->status());
            Log::info('Gemini Body: ' . $response->body());

            if ($response->successful()) {
                return $response->json('candidates.0.content.parts.0.text')
                    ?? 'Analisis tidak tersedia.';
            }

            Log::error('Gemini Failed: ' . $response->status() . ' - ' . $response->body());
            return 'Analisis AI sementara tidak tersedia.';

        } catch (\Exception $e) {
            Log::error('Gemini Exception: ' . $e->getMessage());
            return 'Analisis AI sementara tidak tersedia.';
        }
    }
}
