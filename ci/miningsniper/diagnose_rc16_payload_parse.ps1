param([Parameter(Mandatory)][string]$MainPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$raw=Get-Content -Raw -LiteralPath $MainPath
$sha=(Get-FileHash -Algorithm SHA256 -LiteralPath $MainPath).Hash.ToLowerInvariant()
$tok=$null;$err=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($MainPath,[ref]$tok,[ref]$err)
if($err.Count-gt0){throw ('MAIN_PARSE_FAIL count='+$err.Count)}

function Get-LiteralPayload([string]$Name){
  $a=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.AssignmentStatementAst]},$true)|Where-Object{
    $_.Left-is[Management.Automation.Language.VariableExpressionAst] -and $_.Left.VariablePath.UserPath-eq$Name
  }|Select-Object -First 1)
  if($a.Count-ne1){throw ('PAYLOAD_ASSIGNMENT_MISSING '+$Name)}
  $rhs=$a[0].Right
  if($rhs-is[Management.Automation.Language.StringConstantExpressionAst]){return [string]$rhs.Value}
  if($rhs-is[Management.Automation.Language.CommandExpressionAst] -and $rhs.Expression-is[Management.Automation.Language.StringConstantExpressionAst]){return [string]$rhs.Expression.Value}
  throw ('PAYLOAD_LITERAL_SHAPE_UNSUPPORTED '+$Name+' rhs='+$rhs.GetType().FullName)
}

Write-Host ('CANDIDATE_SHA256 '+$sha)
$summary=[ordered]@{}
foreach($name in @('script:SupervisorPayload','script:DutyFixturePayload','script:StopPayload','script:StatusPayload','script:ExportPayload')){
  $payload=Get-LiteralPayload $name
  $lines=$payload -split "`r?`n"
  $pt=$null;$pe=$null
  [void][Management.Automation.Language.Parser]::ParseInput($payload,[ref]$pt,[ref]$pe)
  $summary[$name]=[ordered]@{error_count=$pe.Count;errors=@()}
  Write-Host ('PAYLOAD_PARSE_BEGIN name='+$name+' chars='+$payload.Length+' lines='+$lines.Count+' error_count='+$pe.Count)
  foreach($e in @($pe)){
    $ln=[int]$e.Extent.StartLineNumber
    $col=[int]$e.Extent.StartColumnNumber
    $src=if($ln-ge1-and$ln-le$lines.Count){[string]$lines[$ln-1]}else{''}
    $rec=[ordered]@{id=$e.ErrorId;line=$ln;column=$col;extent=[string]$e.Extent.Text;message=[string]$e.Message;source=$src}
    $summary[$name].errors+=,$rec
    Write-Host ('PAYLOAD_PARSE_ERROR name='+$name+' id='+$e.ErrorId+' line='+$ln+' col='+$col+' extent=['+[string]$e.Extent.Text+']')
    Write-Host ('PAYLOAD_SOURCE['+$name+':'+$ln+'] '+$src)
  }
  Write-Host ('PAYLOAD_PARSE_END name='+$name)
}
$summary|ConvertTo-Json -Depth 20|Set-Content -LiteralPath 'RC16_PAYLOAD_PARSE_DIAGNOSTIC.json' -Encoding utf8
Write-Host 'RC16_PAYLOAD_PARSE_DIAGNOSTIC_COMPLETE'
