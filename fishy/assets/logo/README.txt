FishCare logo files
===================
Extract this zip into your Flutter project folder (the one with pubspec.yaml) so the files end up in assets/logo/.

  app_icon.png             1024x1024, full square, no transparency. App launcher icon (Android + iOS).
  app_icon_foreground.png  1024x1024, transparent. Android "adaptive icon" foreground (fish sits inside the safe zone).
  logo_with_name.png       2400x880. Icon + "FishCare" name, for splash screen / about page / documents.
  app_icon.svg             Vector master of the icon (edit or scale freely).

Set the launcher icon (run in the project folder):

  flutter pub add --dev flutter_launcher_icons

Add this block to pubspec.yaml, at the far left (NOT inside "flutter:"):

  flutter_launcher_icons:
    android: true
    ios: true
    image_path: "assets/logo/app_icon.png"
    adaptive_icon_background: "#0B1424"
    adaptive_icon_foreground: "assets/logo/app_icon_foreground.png"
    remove_alpha_ios: true

Then:

  flutter pub get
  dart run flutter_launcher_icons
  flutter clean
  flutter run          (uninstall the old app first if the old icon still shows)

To use a logo inside the app, list the folder under flutter: > assets: in pubspec.yaml
(add the line   - assets/logo/   next to your other asset lines) and use:

  Image.asset('assets/logo/logo_with_name.png')
