package com.example.pymes2

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Build

class MainActivity : FlutterFragmentActivity() {
    override fun onPostResume() {
        super.onPostResume()
        // Habilitar renderización por software para Google Maps en emuladores
        if (Build.FINGERPRINT.contains("generic") || Build.FINGERPRINT.contains("unknown")) {
            // Esto es un emulador
        }
    }
}
