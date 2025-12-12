package com.example.pymes2

import io.flutter.embedding.android.FlutterActivity
import android.os.Build

class MainActivity : FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        // Habilitar renderización por software para Google Maps en emuladores
        if (Build.FINGERPRINT.contains("generic") || Build.FINGERPRINT.contains("unknown")) {
            // Esto es un emulador
        }
    }
}
