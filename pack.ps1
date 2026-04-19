$ErrorActionPreference = "Stop"

$RAW_DIR = "raw"
$BUILD_DIR = "build"
$BIN_DIR = "bin"
$FONT_URL = "https://github.com/Warren2060/ChillRound/releases/download/v3.200/ChillRoundF_v3.200.zip"
$FONT_PATH = Join-Path $BUILD_DIR "ChillRoundF_v3.200\ChillRoundFBold.ttf"

@($RAW_DIR, $BUILD_DIR, "$BUILD_DIR\romfs", $BIN_DIR) | ForEach-Object { 
    if (!(Test-Path $_)) { New-Item -ItemType Directory -Path $_ } 
}

if (!(Test-Path $FONT_PATH)) {
    Write-Host "Downloading font..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $FONT_URL -OutFile "$BUILD_DIR\font.zip"
    
    if ((Get-Item "$BUILD_DIR\font.zip").Length -lt 1MB) {
        Remove-Item "$BUILD_DIR\font.zip"
        throw "Downloaded font file is too small, check your network."
    }

    Expand-Archive -Path "$BUILD_DIR\font.zip" -DestinationPath $BUILD_DIR -Force
    Remove-Item "$BUILD_DIR\font.zip"
}

$roms = @("data", "patch", "append")
foreach ($name in $roms) {
    $targetPath = Join-Path $RAW_DIR $name
    $romFile = Join-Path $RAW_DIR "$name.rom"
    
    if (!(Test-Path $targetPath)) {
        if (Test-Path $romFile) {
            Write-Host "Extracting $name.rom..." -ForegroundColor Yellow
            & "$BIN_DIR\shin-tl" rom extract $romFile $targetPath
        }
        else {
            Write-Warning "Missing $romFile, skipping extraction."
        }
    }
}

$buildPatchPath = Join-Path $BUILD_DIR "patch"
if (!(Test-Path $buildPatchPath)) {
    Copy-Item -Path (Join-Path $RAW_DIR "patch") -Destination $buildPatchPath -Recurse -Force
}

$mainCsvPath = Join-Path $BUILD_DIR "main.csv"
if (!(Test-Path $mainCsvPath)) {
    Write-Host "Extracting script data to CSV..." -ForegroundColor Cyan
    & "$BIN_DIR\shin-tl" snr read higurashi-hou-v2 "$RAW_DIR\patch\main.snr" "$mainCsvPath"
}

python script-tool.py import --main "$mainCsvPath" --text "higurashi-hou.csv"
& python create-mapping.py
& "$BIN_DIR\fnt4-tool" rebuild "$RAW_DIR\data\newrodin.fnt" "$BUILD_DIR\patch\newrodin.fnt" $FONT_PATH -s 102 --letter-spacing 2 -c "$BUILD_DIR\mapping.toml"
& "$BIN_DIR\shin-tl" snr rewrite higurashi-hou-v2 "$RAW_DIR\patch\main.snr" "$BUILD_DIR\main-mapped.csv" "$BUILD_DIR\patch\main.snr"
& "$BIN_DIR\shin-tl" rom create --rom-version higurashi-hou-v2 "$BUILD_DIR\patch" "$BUILD_DIR\romfs\patch.rom"

Write-Host "Build Complete!" -ForegroundColor Green

pause