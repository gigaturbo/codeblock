# Run the nine specs inside Luanti, against the fixture game in tests/game.
#
# Six of them also run under a bare Lua 5.1 in CI; forms_spec, stepper_spec and
# integration_spec need the mod loaded and only run here.
#
# The one rule that must not be broken: enabling the suite means writing
# codeblock_run_tests into the user's real minetest.conf, because Luanti's
# --config flag is silently ignored for it. The setting is stripped in a finally
# block, on the failure path too. Left behind, it runs the suite on every launch.
#
#   powershell -File scripts/run_tests.ps1 [-KeepWorld] [-Exe <path>]

[CmdletBinding()]
param(
    [string]$Exe = "$env:LOCALAPPDATA\luanti\5.17.0\bin\luanti.exe",
    [int]$Seconds = 25,
    [switch]$KeepWorld
)

$ErrorActionPreference = "Stop"

$repo  = Split-Path -Parent $PSScriptRoot
$game  = Join-Path $env:APPDATA "Minetest\games\cbtest"
$link  = Join-Path $game "mods\codeblock"
$uconf = Join-Path $env:APPDATA "Minetest\minetest.conf"

if (-not (Test-Path $Exe))   { throw "engine not found: $Exe" }
if (-not (Test-Path $uconf)) { throw "user config not found: $uconf" }

# --- assemble the fixture game ------------------------------------------------
# The game cannot live in the repository, because it has to contain the
# repository as one of its mods. So it is assembled here: tests/game copied for
# game.conf and the stubs, and a junction for the mod itself.
#
# The junction is removed with rmdir and never with Remove-Item -Recurse, which
# follows a junction and would delete the repository behind it.
if (Test-Path $link) { cmd /c rmdir "$link" | Out-Null }
if (Test-Path $game) { Remove-Item -Recurse -Force $game }

Copy-Item -Recurse (Join-Path $repo "tests\game") $game
cmd /c mklink /J "$link" "$repo" | Out-Null
if (-not (Test-Path (Join-Path $link "mod.conf"))) {
    throw "junction did not take: $link"
}

# --- boot, capture, kill ------------------------------------------------------
$world = Join-Path $env:TEMP ("cb_test_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$out   = "$world.out"
$err   = "$world.err"

Add-Content -Path $uconf -Encoding utf8 -Value "codeblock_run_tests = true"
try {
    $p = Start-Process -FilePath $Exe -PassThru -NoNewWindow `
        -ArgumentList @("--server", "--gameid", "cbtest", "--world", $world) `
        -RedirectStandardOutput $out -RedirectStandardError $err
    Start-Sleep -Seconds $Seconds
    if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
    Start-Sleep -Seconds 2
}
finally {
    (Get-Content $uconf) |
        Where-Object { $_ -notmatch '^codeblock_run_tests' } |
        Set-Content $uconf -Encoding utf8
}

# --- report -------------------------------------------------------------------
Get-Content $out | Select-String "passed|failed|FAIL|want|got|skipped|xfail"

"--- errors ---"
$e = Get-Content $err | Select-String "ModError|attempt to|traceback|invalid|Blocked|Failed to load"
if ($e) { $e | Select-Object -First 10 } else { "none" }

if (-not $KeepWorld) {
    Remove-Item -Recurse -Force $world -ErrorAction SilentlyContinue
    Remove-Item -Force $out, $err -ErrorAction SilentlyContinue
} else {
    "world kept at $world"
}
