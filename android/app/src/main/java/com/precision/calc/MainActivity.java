package com.precision.calc;

import android.os.Bundle;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/**
 * Native security controls that cannot be reliably implemented in Dart.
 * Sensitive-screen protection is enabled only while the crypto workspace is
 * visible, so ordinary calculator results can still be screenshotted.
 */
public final class MainActivity extends FlutterActivity {
    private static final String SECURITY_CHANNEL = "com.precision.calc/security";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                SECURITY_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if ("setSecureScreen".equals(call.method)) {
                Boolean enabled = call.argument("enabled");
                runOnUiThread(() -> setSecureScreen(Boolean.TRUE.equals(enabled)));
                result.success(null);
            } else {
                result.notImplemented();
            }
        });
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Protect the first restored frame until Flutter confirms which screen
        // is visible. AppShell clears the flag for ordinary calculator pages.
        if (savedInstanceState != null) {
            setSecureScreen(true);
        }
        super.onCreate(savedInstanceState);
    }

    private void setSecureScreen(boolean enabled) {
        if (enabled) {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
        } else {
            getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
        }
    }
}
