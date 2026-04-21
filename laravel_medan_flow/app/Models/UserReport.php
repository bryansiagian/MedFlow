<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserReport extends Model
{
    protected $fillable = [
        'type',
        'latitude',
        'longitude',
        'description',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'latitude'   => 'float',
        'longitude'  => 'float',
    ];
}
