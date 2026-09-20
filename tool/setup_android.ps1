# Regenerates the Gradle scaffolding of android/ from *your* Flutter version.
#
# The repository ships hand-written Gradle files (AGP 8.7.3 / Kotlin 2.1.0 /
# Gradle 8.12). They work with Flutter 3.27 and newer. If `flutter build apk`
# complains about plugin or Gradle versions, run this once:
#
#     powershell -ExecutionPolicy Bypass -File tool\setup_android.ps1
#
# It keeps everything that is ours (manifests, MainActivity, icons, styles) and
# replaces only the build scripts and the Gradle wrapper.

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $projectRoot "android"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "flutter is not on PATH. Install the Flutter SDK first."
}

Write-Host "Flutter:" (Get-Command flutter).Source

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("yaqinda-scaffold-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $temp | Out-Null

try {
    Write-Host "Generating a throwaway project in $temp ..."
    & flutter create --platforms=android --org uz.yaqinda --project-name demo $temp | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Error "flutter create failed" }

    $src = Join-Path $temp "android"

    # Build scripts and the wrapper come from the generated project; the older
    # Groovy files are removed so the two flavours cannot both be present.
    foreach ($name in @("settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "gradle.properties")) {
        $p = Join-Path $androidDir $name
        if (Test-Path $p) { Remove-Item $p -Force }
    }
    foreach ($name in @("app\build.gradle", "app\build.gradle.kts")) {
        $p = Join-Path $androidDir $name
        if (Test-Path $p) { Remove-Item $p -Force }
    }

    Get-ChildItem -Path $src -File | Where-Object {
        $_.Name -like "*.gradle" -or $_.Name -like "*.gradle.kts" -or
        $_.Name -eq "gradle.properties" -or $_.Name -like "gradlew*"
    } | ForEach-Object { Copy-Item $_.FullName (Join-Path $androidDir $_.Name) -Force }

    # Replace the wrapper wholesale; copying onto an existing directory would
    # nest it as android\gradle\gradle.
    $wrapperSrc = Join-Path $src "gradle"
    $wrapperDst = Join-Path $androidDir "gradle"
    if (Test-Path $wrapperSrc) {
        if (Test-Path $wrapperDst) { Remove-Item $wrapperDst -Recurse -Force }
        Copy-Item $wrapperSrc $wrapperDst -Recurse -Force
    }

    Get-ChildItem -Path (Join-Path $src "app") -File | Where-Object { $_.Name -like "build.gradle*" } |
        ForEach-Object { Copy-Item $_.FullName (Join-Path $androidDir ("app\" + $_.Name)) -Force }

    # minSdk 24 (Android 7.0), as the brief asks for.
    foreach ($name in @("app\build.gradle", "app\build.gradle.kts")) {
        $p = Join-Path $androidDir $name
        if (Test-Path $p) {
            $text = Get-Content $p -Raw
            $text = $text -replace "minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 24"
            $text = $text -replace "minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 24"
            Set-Content -Path $p -Value $text -Encoding utf8
            Write-Host "Patched minSdk in $name"
        }
    }

    Write-Host ""
    Write-Host "Done. The manifests, MainActivity.kt and res/ were left untouched."
    Write-Host "Now run:  flutter pub get  &&  flutter build apk --release"
}
finally {
    if (Test-Path $temp) { Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue }
}
