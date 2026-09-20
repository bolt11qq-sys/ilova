#!/usr/bin/env bash
# Regenerates the Gradle scaffolding of android/ from *your* Flutter version.
# See tool/setup_android.ps1 for the Windows version and the rationale.
#
#     bash tool/setup_android.sh

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
android_dir="$project_root/android"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is not on PATH. Install the Flutter SDK first." >&2
  exit 1
fi

echo "Flutter: $(command -v flutter)"

temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT

echo "Generating a throwaway project in $temp ..."
flutter create --platforms=android --org uz.yaqinda --project-name demo "$temp" >/dev/null

src="$temp/android"

# Build scripts and the wrapper come from the generated project; the older
# Groovy files are removed so the two flavours cannot both be present.
rm -f "$android_dir"/settings.gradle "$android_dir"/settings.gradle.kts \
      "$android_dir"/build.gradle "$android_dir"/build.gradle.kts \
      "$android_dir"/gradle.properties \
      "$android_dir"/app/build.gradle "$android_dir"/app/build.gradle.kts

find "$src" -maxdepth 1 -type f \
  \( -name '*.gradle' -o -name '*.gradle.kts' -o -name 'gradle.properties' \
     -o -name 'gradlew' -o -name 'gradlew.bat' \) \
  -exec cp -f {} "$android_dir"/ \;

# Replace the wrapper wholesale; copying onto an existing directory would
# nest it as android/gradle/gradle.
rm -rf "$android_dir/gradle"
cp -rf "$src/gradle" "$android_dir/gradle" 2>/dev/null || true

find "$src/app" -maxdepth 1 -type f -name 'build.gradle*' \
  -exec cp -f {} "$android_dir"/app/ \;
chmod +x "$android_dir/gradlew" 2>/dev/null || true

# minSdk 24 (Android 7.0), as the brief asks for.
for f in "$android_dir"/app/build.gradle "$android_dir"/app/build.gradle.kts; do
  [ -f "$f" ] || continue
  sed -i.bak -E 's/minSdk[[:space:]]*=[[:space:]]*flutter\.minSdkVersion/minSdk = 24/; s/minSdkVersion[[:space:]]+flutter\.minSdkVersion/minSdkVersion 24/' "$f"
  rm -f "$f.bak"
  echo "Patched minSdk in $(basename "$f")"
done

echo
echo "Done. The manifests, MainActivity.kt and res/ were left untouched."
echo "Now run:  flutter pub get && flutter build apk --release"
