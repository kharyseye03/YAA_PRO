package gn.yaa.pro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /**
     * `moveToBackground` : met l'app en arrière-plan, comme le bouton
     * Accueil, sans détruire l'activité.
     *
     * Utilisé par l'écran de mission pour le bouton retour. Par défaut
     * Android ferme l'activité : le guidage Google continue alors de
     * parler dans son service de premier plan, mais l'interface est
     * perdue — au retour, l'app repart du splash et plante en recréant
     * la carte pendant que le guidage tourne encore.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gn.yaa.pro/app")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "moveToBackground" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
