$ErrorActionPreference = "Stop"
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\app"))
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()
Write-Host "Preview: http://localhost:8080/"

$contentTypes = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
}

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $relativePath = $context.Request.Url.AbsolutePath.TrimStart("/")
    if ([string]::IsNullOrWhiteSpace($relativePath)) { $relativePath = "index.html" }
    $filePath = [System.IO.Path]::GetFullPath((Join-Path $root $relativePath))

    if ($filePath.StartsWith($root) -and [System.IO.File]::Exists($filePath)) {
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $extension = [System.IO.Path]::GetExtension($filePath)
      $context.Response.ContentType = $contentTypes[$extension]
      $context.Response.StatusCode = 200
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $context.Response.StatusCode = 404
    }
    $context.Response.Close()
  }
} finally {
  $listener.Stop()
}
