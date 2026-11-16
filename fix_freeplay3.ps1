$content = [System.IO.File]::ReadAllText("source/FreeplayState.hx")
$marker = 'tankman", 0x010);'
$idx = $content.IndexOf($marker)
Write-Output "Index: $idx"
$afterMarker = $content.Substring($idx + $marker.Length)
Write-Output "After marker (first 60 chars):"
Write-Output $afterMarker.Substring(0, 60)

# Find the end of "// LOAD CHARACTERS" line
$endIdx = $afterMarker.IndexOf("// LOAD CHARACTERS") + "// LOAD CHARACTERS".Length
Write-Output "End index of LOAD CHARACTERS line: $endIdx"

$before = $content.Substring(0, $idx + $marker.Length)
$after = $content.Substring($idx + $marker.Length + $endIdx)

$insertion = '		addSong("Shaggy3d", 1, "shaggy3d", 0x111, true, true, "shaggy/shaggy3d", "Shaggy3d", "shaggy-shaggy3d");' + [Environment]::NewLine + '		addSong("Shag", 1, "shaggy3d", 0x111, true, true, "shaggy/shag", "Shag", "shaggy-shag");' + [Environment]::NewLine

$newContent = $before + [Environment]::NewLine + $insertion + $after
[System.IO.File]::WriteAllText("source/FreeplayState.hx", $newContent)
Write-Output "SUCCESS"
