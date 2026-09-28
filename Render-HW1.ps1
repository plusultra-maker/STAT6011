param([ValidateSet('all','html','pdf')][string]$Format = 'all')
$ErrorActionPreference = 'Stop'
$courseRoot = $PSScriptRoot
$env:RSTUDIO_PANDOC = (Get-ChildItem "$courseRoot\.tools\pandoc" -Filter pandoc.exe -Recurse | Select-Object -First 1).DirectoryName
$env:PATH = "$courseRoot\.tools\TinyTeX\bin\windows;$env:PATH"
$env:LANG = 'en_US.UTF-8'
Remove-Item Env:LC_ALL,Env:LC_CTYPE,Env:LC_COLLATE,Env:LC_MONETARY,Env:LC_TIME -ErrorAction SilentlyContinue
Push-Location "$courseRoot\hw1"
try {
  & "$courseRoot\.tools\R\bin\Rscript.exe" --vanilla "$courseRoot\render_hw1.R" $Format
  if ($LASTEXITCODE -ne 0) { throw 'R Markdown rendering failed.' }
} finally { Pop-Location }
