/// NOTE: The app now runs fully on-device via TFLite (see
/// lib/services/tflite_service.dart) and does NOT use this URL for
/// predictions. This is kept only if you want to point some other part
/// of the app at the FastAPI backend (e.g. for testing against a newer
/// server-side model before re-exporting it to TFLite).
///
/// - Web (Chrome) or desktop: http://localhost:8000
/// - Android emulator -> host machine: http://10.0.2.2:8000
/// - Physical device on same Wi-Fi: http://<your-machine-LAN-IP>:8000
/// - Deployed backend: its public URL
const String apiBaseUrl = 'http://localhost:8000';
