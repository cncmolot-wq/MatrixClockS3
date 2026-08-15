param([Parameter(Mandatory)][string]$PwshPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$src=Join-Path $PSScriptRoot 'rebuild_validate_rc16.ps1'
$tmp=Join-Path $PSScriptRoot 'rebuild_validate_rc16_v2.generated.ps1'
$text=Get-Content -Raw -LiteralPath $src
$old=@'
function Replace-PayloadAssignment([string]$Main,[string]$Name,[string]$Payload){
  $pattern='(?ms)\$script:'+[regex]::Escape($Name)+"=@'\r?\n.*?\r?\n'@"
  $replacement='$script:'+$Name+"=@'`n"+$Payload.TrimEnd("`r","`n")+"`n'@"
  $rx=[regex]::new($pattern)
  $m=$rx.Match($Main)
  if(-not$m.Success){throw ('Cannot locate payload assignment '+$Name)}
  if($rx.Matches($Main).Count-ne1){throw ('Payload assignment regex not unique '+$Name)}
  return $Main.Substring(0,$m.Index)+$replacement+$Main.Substring($m.Index+$m.Length)
}
'@
$new=@'
function Replace-PayloadAssignment([string]$Main,[string]$Name,[string]$Payload){
  $t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($Main,[ref]$t,[ref]$e)
  if($e.Count-gt0){throw ('Main parse before payload replacement failed '+$Name+': '+(($e|ForEach-Object{$_.ErrorId+':'+$_.Message})-join' | '))}
  $assign=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$script:'+$Name)},$true)|Sort-Object {$_.Extent.StartOffset})
  $replacement='$script:'+$Name+"=@'`n"+$Payload.TrimEnd("`r","`n")+"`n'@"
  if($Name-eq'ExportPayload'){
    if($assign.Count-ne2){throw ('Expected exactly two forensic ExportPayload assignments, got '+$assign.Count)}
    # Both were proven top-level in the same script block. The later assignment is effective at runtime.
    # Replace the later one first, then delete the earlier duplicate so offset changes cannot corrupt selection.
    $late=$assign[1].Extent;$early=$assign[0].Extent
    $afterLate=Replace-Extent $Main $late $replacement
    return $afterLate.Substring(0,$early.StartOffset)+$afterLate.Substring($early.EndOffset)
  }
  if($assign.Count-ne1){throw ('Payload AST assignment count '+$Name+' = '+$assign.Count)}
  return Replace-Extent $Main $assign[0].Extent $replacement
}
'@
$first=$text.IndexOf($old,[StringComparison]::Ordinal)
$last=$text.LastIndexOf($old,[StringComparison]::Ordinal)
if($first-lt0-or$first-ne$last){throw ('Expected exactly one old replacement function, first='+$first+' last='+$last)}
$patched=$text.Substring(0,$first)+$new+$text.Substring($first+$old.Length)
[IO.File]::WriteAllText($tmp,$patched,[Text.UTF8Encoding]::new($false))
$tok=$null;$err=$null;[void][Management.Automation.Language.Parser]::ParseFile($tmp,[ref]$tok,[ref]$err)
if($err.Count-gt0){throw ('Generated validator ParseFile failed: '+(($err|ForEach-Object{$_.ErrorId+':'+$_.Message})-join' | '))}
& $tmp -PwshPath $PwshPath
if($LASTEXITCODE-ne0){exit $LASTEXITCODE}
