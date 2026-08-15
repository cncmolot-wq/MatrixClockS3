param([Parameter(Mandatory)][string]$MainPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$tok=$null;$err=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($MainPath,[ref]$tok,[ref]$err)
if($err.Count-gt0){throw ('MAIN_PARSE_FAIL count='+$err.Count)}
foreach($Name in @('script:SupervisorPayload','script:DutyFixturePayload','script:StopPayload','script:StatusPayload','script:ExportPayload')){
  $a=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.AssignmentStatementAst]},$true)|Where-Object{
    $_.Left-is[Management.Automation.Language.VariableExpressionAst] -and $_.Left.VariablePath.UserPath-eq$Name
  }|Select-Object -First 1)
  if($a.Count-ne1){throw ('PAYLOAD_ASSIGNMENT_MISSING '+$Name)}
  $rhs=$a[0].Right
  Write-Host ('PAYLOAD_AST name='+$Name+' rhs_type='+$rhs.GetType().FullName)
  Write-Host ('PAYLOAD_AST extent_prefix='+(($rhs.Extent.Text.Substring(0,[Math]::Min(80,$rhs.Extent.Text.Length)))-replace"`r|`n",' '))
  $children=@($rhs.FindAll({param($n)$true},$true)|Select-Object -First 6)
  foreach($c in $children){Write-Host ('PAYLOAD_AST child_type='+$c.GetType().FullName+' child_prefix='+(($c.Extent.Text.Substring(0,[Math]::Min(50,$c.Extent.Text.Length)))-replace"`r|`n",' '))}
  if($rhs.PSObject.Methods.Name-contains'SafeGetValue'){
    try{$v=$rhs.SafeGetValue();Write-Host ('PAYLOAD_AST safe_value_type='+$(if($null-eq$v){'NULL'}else{$v.GetType().FullName})+' length='+$(if($v-is[string]){$v.Length}else{-1}))}catch{Write-Host ('PAYLOAD_AST safe_value_error='+$_.Exception.Message)}
  }
}
Write-Host 'PAYLOAD_AST_DIAGNOSTIC_COMPLETE'
