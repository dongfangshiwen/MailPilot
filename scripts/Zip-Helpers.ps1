function Add-ZipFile {
    param(
        [IO.Compression.ZipArchive]$Archive,
        [string]$Source,
        [string]$EntryName
    )
    # Windows process-output handles can remain open after the emulator exits.
    # Share reads/writes so completed evidence logs can still be archived.
    $inputStream=[IO.File]::Open($Source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try {
        $entry=$Archive.CreateEntry($EntryName,[IO.Compression.CompressionLevel]::Optimal)
        $entryStream=$entry.Open()
        try { $inputStream.CopyTo($entryStream) } finally { $entryStream.Dispose() }
    } finally { $inputStream.Dispose() }
}
