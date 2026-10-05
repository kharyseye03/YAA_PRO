package gn.yaa.pro

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gn.yaa.pro/app")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Met l'app en arrière-plan, comme le bouton Accueil,
                    // sans détruire l'activité.
                    //
                    // Utilisé par l'écran de mission pour le bouton retour.
                    // Par défaut Android ferme l'activité : le guidage Google
                    // continue alors de parler dans son service de premier
                    // plan, mais l'interface est perdue — au retour, l'app
                    // repart du splash et plante en recréant la carte pendant
                    // que le guidage tourne encore.
                    "moveToBackground" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }

                    // Demande l'autorisation d'afficher des notifications,
                    // obligatoire depuis Android 13. Sans elle, la
                    // notification du guidage — celle qui ramène à la course
                    // et maintient le service de premier plan — reste
                    // invisible pour le coursier.
                    //
                    // Rien à attendre du résultat : si le coursier refuse, le
                    // guidage fonctionne quand même. Android n'affiche la
                    // demande que deux fois, d'où l'appel au moment d'une
                    // mission plutôt qu'au premier lancement.
                    "requestNotificationPermission" -> {
                        result.success(requestNotificationPermission())
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /** true si les notifications sont déjà autorisées ou non concernées. */
    private fun requestNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        val permission = Manifest.permission.POST_NOTIFICATIONS
        if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            return true
        }
        requestPermissions(arrayOf(permission), NOTIFICATION_PERMISSION_REQUEST)
        return false
    }

    private companion object {
        const val NOTIFICATION_PERMISSION_REQUEST = 1001
    }
}
