param([Parameter(Mandatory)][string]$PwshPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$src=Join-Path $PSScriptRoot 'fixup_rebuild_validator.ps1'
$tmp=Join-Path $PSScriptRoot 'fixup_rebuild_validator_v4.generated.ps1'
$text=Get-Content -Raw -LiteralPath $src
$old='$simFail=$simPass.Clone();$simFail.controlEffect=$false'
$new='$simFail=[ordered]@{productive40=$true;lowerProductiveCount=1;timingOk=$true;controlEffect=$false;poolOk=$true;threadControl=$true}'
$first=$text.IndexOf($old,[StringComparison]::Ordinal)
$last=$text.LastIndexOf($old,[StringComparison]::Ordinal)
if($first-lt0-or$first-ne$last){throw ('Expected one OrderedDictionary Clone simulation line, first='+$first+' last='+$last)}
$patched=$text.Substring(0,$first)+$new+$text.Substring($first+$old.Length)
[IO.File]::WriteAllText($tmp,$patched,[Text.UTF8Encoding]::new($false))
$t=$null;$e=$null;[void][Management.Automation.Language.Parser]::ParseFile($tmp,[ref]$t,[ref]$e)
if($e.Count-gt0){throw ('Generated outer validator ParseFile failed: '+(($e|ForEach-Object{$_.ErrorId+':'+$_.Message})-join' | '))}
& $tmp -PwshPath $PwshPath
if($LASTEXITCODE-ne0){exit $LASTEXITCODE}
