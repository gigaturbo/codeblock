# Run the nine specs inside Luanti, against the fixture game in tests/game.
#
# Six of them also run under a bare Lua 5.1 in CI, and CI runs all nine in
# upstream's server container. This is the same run on the engine the mod is
# actually developed against.
#
# The suite is enabled by tests/game/minetest.conf, a game default, so this
# script writes nothing into the player's real minetest.conf and has nothing to
# strip afterwards - which is what the whole shape of this file used to be built
# around. That same game conf asks the server to shut itself down once the suite
# has reported, so there is no fixed sleep here either. (C24)
#
#   powershell -File scripts/run_tests.ps1 [-KeepWorld] [-Exe <path>]

[CmdletBinding()]
param(
    [string]$Exe = "$env:LOCALAPPDATA\luanti\5.17.0\bin\luanti.exe",
    # Only a ceiling on a run that ends itself in about a second. Reaching it
    # means the suite never reported, and the report below then says so.
    [int]$TimeoutSeconds = 120,
    [switch]$KeepWorld
)

$ErrorActionPreference = "Stop"

$repo  = Split-Path -Parent $PSScriptRoot
$game  = Join-Path $env:APPDATA "Minetest\games\cbtest"
$link  = Join-Path $game "mods\codeblock"

if (-not (Test-Path $Exe)) { throw "engine not found: $Exe" }

# --- assemble the fixture game ------------------------------------------------
# The game cannot live in the repository, because it has to contain the
# repository as one of its mods. So it is assembled here: tests/game copied for
# game.conf, minetest.conf and cbfixture, and a junction for the mod itself.
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

# --- boot and capture ---------------------------------------------------------
$world = Join-Path $env:TEMP ("cb_test_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$out   = "$world.out"
$err   = "$world.err"

$p = Start-Process -FilePath $Exe -PassThru -NoNewWindow `
    -ArgumentList @("--server", "--gameid", "cbtest", "--world", $world) `
    -RedirectStandardOutput $out -RedirectStandardError $err

# The game conf asks for a shutdown once the suite has reported, so waiting for
# the process is waiting for the suite. Kill only if it overruns, which means
# something other than the suite is holding the server up.
if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
    "the server did not exit within $TimeoutSeconds s - killing it"
    Stop-Process -Id $p.Id -Force
    Start-Sleep -Seconds 2
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
