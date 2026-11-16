$content = [System.IO.File]::ReadAllText("source/FreeplayState.hx")
$old = 'tankman", 0x010);' + [Environment]::NewLine + '		// LOAD CHARACTERS'
$new = 'tankman", 0x010);' + [Environment]::NewLine + '		addSong("Shaggy3d", 1, "shaggy3d", 0x111, true, true, "shaggy/shaggy3d", "Shaggy3d", "shaggy-shaggy3d");' + [Environment]::NewLine + '		addSong("Shag", 1, "shaggy3d", 0x111, true, true, "shaggy/shag", "Shag", "shaggy-shag");' + [Environment]::NewLine + '		// LOAD CHARACTERS'

Write-Output "Content length: $($content.Length)"
Write-Output "Contains old: $($content.Contains($old))"

if ($content.Contains($old)) {
    $newContent = $content.Replace($old, $new)
    [System.IO.File]::WriteAllText("source/FreeplayState.hx", $newContent)
    Write-Output "SUCCESS: Replaced"
} else {
    Write-Output "NOT FOUND"
    $idx = $content.IndexOf('tankman", 0x010);')
    Write-Output "Index: $idx"
    Write-Output $content.Substring($idx, 60)
}
