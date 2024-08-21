package com.example.untitled1
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.untitled1/permissions"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestExactAlarmPermission" -> {
                        Log.d(TAG, "Solicitud de permiso de alarma exacta recibida")
                        val permissionGranted = requestExactAlarmPermission()
                        Log.d(TAG, "Permiso de alarma exacta concedido: $permissionGranted")
                        result.success(permissionGranted)
                    }
                    else -> {
                        Log.d(TAG, "Método no implementado: ${call.method}")
                        result.notImplemented()
                    }
                }
            }
    }

    private fun requestExactAlarmPermission(): Boolean {
        // Verifica si el permiso de alarma exacta está concedido
        val hasPermission = Settings.System.canWrite(this)
        Log.d(TAG, "Verificación del permiso de escritura en configuración: $hasPermission")

        if (hasPermission) {
            return true
        }

        // Solicita el permiso de escritura en configuración
        Log.d(TAG, "Solicitando permiso de escritura en configuración")
        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)

        return false
    }
}
