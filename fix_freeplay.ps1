$content = Get-Content source/FreeplayState.hx -Raw -Encoding utf8
$old = 'tankman", 0x010);' + "`r`n" + '		// LOAD CHARACTERS'
$new = 'tankman", 0x010);' + "`r`n" + '		addSong("Shaggy3d", 1, "shaggy3d", 0x111, true, true, "shaggy/shaggy3d", "Shaggy3d", "shaggy-shaggy3d");' + "`r`n" + '		addSong("Shag", 1, "shaggy3d", 0x111, true, true, "shaggy/shag", "Shag", "shaggy-shag");' + "`r`n" + '		// LOAD CHARACTERS'

if ($content.Contains($old)) {
    $newContent = $content.Replace($old, $new)
    $newContent | Set-Content -Encoding utf8 source/FreeplayState.hx
    "SUCCESS: Replaced"
} else {
    "NOT FOUND"
    # Show what's around tankman
    $idx = $content.IndexOf('tankman", 0x010);')
    $content.Substring($idx, 60)
}
