param([Parameter(Mandatory)][string]$PwshPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$src=Join-Path $PSScriptRoot 'rebuild_validate_rc16.ps1'
$tmp=Join-Path $PSScriptRoot 'rebuild_validate_rc16_v3.generated.ps1'
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
function Get-PayloadAssignments([string]$Main,[string]$Name){
  $t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($Main,[ref]$t,[ref]$e)
  if($e.Count-gt0){throw ('Main parse before payload operation failed '+$Name+': '+(($e|ForEach-Object{$_.ErrorId+':'+$_.Message})-join' | '))}
  return @($ast.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$script:'+$Name)},$true)|Sort-Object {$_.Extent.StartOffset})
}
function Get-EffectivePayloadValue([string]$Main,[string]$Name){
  $assign=@(Get-PayloadAssignments $Main $Name)
  if($assign.Count-lt1){throw ('Payload missing '+$Name)}
  $rhs=$assign[-1].Right
  if($rhs -is [Management.Automation.Language.CommandExpressionAst] -and $rhs.Expression -is [Management.Automation.Language.StringConstantExpressionAst]){return [string]$rhs.Expression.Value}
  if($rhs -is [Management.Automation.Language.StringConstantExpressionAst]){return [string]$rhs.Value}
  throw ('Unsupported effective payload AST '+$Name+': '+$rhs.GetType().FullName)
}
function Replace-PayloadAssignment([string]$Main,[string]$Name,[string]$Payload){
  $assign=@(Get-PayloadAssignments $Main $Name)
  $replacement='$script:'+$Name+"=@'`n"+$Payload.TrimEnd("`r","`n")+"`n'@"
  if($assign.Count-eq2){
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
$needle=@'
$text=Replace-PayloadAssignment $text 'ExportPayload' $export
'@
$needle=$needle.Trim()
$insert=@'
foreach($dupName in @('StopPayload','StatusPayload')){
  $effective=Get-EffectivePayloadValue $text $dupName
  $text=Replace-PayloadAssignment $text $dupName $effective
}
$text=Replace-PayloadAssignment $text 'ExportPayload' $export
'@
$insert=$insert.Trim()
$n1=$patched.IndexOf($needle,[StringComparison]::Ordinal);$n2=$patched.LastIndexOf($needle,[StringComparison]::Ordinal)
if($n1-lt0-or$n1-ne$n2){throw ('Expected one ExportPayload replacement call, first='+$n1+' last='+$n2)}
$patched=$patched.Substring(0,$n1)+$insert+$patched.Substring($n1+$needle.Length)
[IO.File]::WriteAllText($tmp,$patched,[Text.UTF8Encoding]::new($false))
$tok=$null;$err=$null;[void][Management.Automation.Language.Parser]::ParseFile($tmp,[ref]$tok,[ref]$err)
if($err.Count-gt0){throw ('Generated validator ParseFile failed: '+(($err|ForEach-Object{$_.ErrorId+':'+$_.Message})-join' | '))}
& $tmp -PwshPath $PwshPath
if($LASTEXITCODE-ne0){exit $LASTEXITCODE}
