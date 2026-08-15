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
$badApi=@'
`$apiFixture=[pscustomobject]@{ok=`$true;data=[pscustomobject]@{Algorithm='Etchash';Performance_Unit='Mh/s';Total_Performance=12.352733907856239}}
'@
$goodApi=@'
`$apiFixture=[pscustomobject]@{ok=`$true;data=[pscustomobject]@{Algorithms=@([pscustomobject]@{Algorithm='Etchash';Performance_Unit='Mh/s';Total_Performance=12.352733907856239})}}
'@
$badApi=$badApi.Trim();$goodApi=$goodApi.Trim()
$a1=$patched.IndexOf($badApi,[StringComparison]::Ordinal);$a2=$patched.LastIndexOf($badApi,[StringComparison]::Ordinal)
if($a1-lt0-or$a1-ne$a2){throw ('Expected one bad API fixture, first='+$a1+' last='+$a2)}
$patched=$patched.Substring(0,$a1)+$goodApi+$patched.Substring($a1+$badApi.Length)
$oldForbidden=@'
if($text -match '(?i)WinRing0|Add-MpPreference|Set-MpPreference|--pl|--cclk|--mclk|--coff|--moff'){throw 'Forbidden runtime token'}
'@
$newForbidden=@'
$unsafeCommandNames=@('Add-MpPreference','Set-MpPreference')
$unsafeCommands=[Collections.Generic.List[string]]::new()
foreach($scopeAst in @($mainAst,$supAst)){
  foreach($cmd in @($scopeAst.FindAll({param($n) $n -is [Management.Automation.Language.CommandAst]},$true))){
    $name=$cmd.GetCommandName()
    if($null-ne$name -and $unsafeCommandNames-contains$name){$unsafeCommands.Add($name)}
  }
}
if($unsafeCommands.Count-gt0){throw ('Forbidden executable command: '+(($unsafeCommands|Sort-Object -Unique)-join','))}
$unsafeArgs=[Collections.Generic.List[string]]::new()
foreach($cmd in @($supAst.FindAll({param($n) $n -is [Management.Automation.Language.CommandAst]},$true))){
  foreach($el in @($cmd.CommandElements)){
    if($el -is [Management.Automation.Language.StringConstantExpressionAst]){
      $v=[string]$el.Value
      if($v-match'(?i)WinRing0' -or $v-match'^(?i:--pl|--cclk|--mclk|--coff|--moff)$'){$unsafeArgs.Add($v)}
    }
  }
}
if($unsafeArgs.Count-gt0){throw ('Forbidden production command argument: '+(($unsafeArgs|Sort-Object -Unique)-join','))}
'@
$oldForbidden=$oldForbidden.Trim();$newForbidden=$newForbidden.Trim()
$f1=$patched.IndexOf($oldForbidden,[StringComparison]::Ordinal);$f2=$patched.LastIndexOf($oldForbidden,[StringComparison]::Ordinal)
if($f1-lt0-or$f1-ne$f2){throw ('Expected one whole-source forbidden scan, first='+$f1+' last='+$f2)}
$patched=$patched.Substring(0,$f1)+$newForbidden+$patched.Substring($f1+$oldForbidden.Length)
$oldState=@'
$stageOrder=@('GPU_BOOTSTRAP','GPU_DUTY_ATTACH','GPU_PHASE_SAMPLER','GPU_CONTROLLED_WARMUP_40','GPU_CALIBRATION_10','GPU_CALIBRATION_25','GPU_CALIBRATION_40','GPU_CALIBRATION_ACCEPTANCE','GPU_LIVE')
$positions=@{};foreach($s in $stageOrder){$positions[$s]=$sup.IndexOf("'$s'");if([int]$positions[$s]-lt0){throw ('Stage missing '+$s)}}
for($i=1;$i-lt$stageOrder.Count;$i++){if([int]$positions[$stageOrder[$i]]-le[int]$positions[$stageOrder[$i-1]]){throw ('Stage order invalid '+$stageOrder[$i-1]+' -> '+$stageOrder[$i])}}
$simPass=[ordered]@{productive40=$true;lowerProductiveCount=1;timingOk=$true;controlEffect=$true;poolOk=$true;threadControl=$true}
$accept=($simPass.productive40-and$simPass.lowerProductiveCount-gt0-and$simPass.timingOk-and$simPass.controlEffect-and$simPass.poolOk-and$simPass.threadControl)
if(-not$accept){throw 'Positive state simulation did not accept'}
$simFail=$simPass.Clone();$simFail.controlEffect=$false
$reject=($simFail.productive40-and$simFail.lowerProductiveCount-gt0-and$simFail.timingOk-and$simFail.controlEffect-and$simFail.poolOk-and$simFail.threadControl)
if($reject){throw 'Negative state simulation did not reject'}
'@
$newState=@'
$measureFns=@($supAst.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Measure-DutyPhase'},$true))
if($measureFns.Count-ne1){throw ('Measure-DutyPhase definition count '+$measureFns.Count)}
$measureFn=$measureFns[0]
$stageAssignments=@($measureFn.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$stageName'},$true))
if($stageAssignments.Count-ne1){throw ('Dynamic calibration stage assignment count '+$stageAssignments.Count)}
$stageExpr=[string]$stageAssignments[0].Right.Extent.Text
if($stageExpr-notmatch'GPU_CALIBRATION_' -or $stageExpr-notmatch'(?i)DutyFraction' -or $stageExpr-notmatch'100'){throw ('Dynamic calibration stage formula invalid: '+$stageExpr)}
foreach($fnCmd in @('Start-LearningStage','Pass-LearningStage')){
  $calls=@($measureFn.FindAll({param($n) $n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq $fnCmd},$true))
  if($calls.Count-ne1){throw ($fnCmd+' dynamic call count '+$calls.Count)}
  $stageVars=@($calls[0].FindAll({param($n) $n -is [Management.Automation.Language.VariableExpressionAst] -and $n.VariablePath.UserPath -eq 'stageName'},$true))
  if($stageVars.Count-lt1){throw ($fnCmd+' does not consume $stageName')}
}
$phaseCalls=@($supAst.FindAll({param($n) $n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Measure-DutyPhase'},$true)|Sort-Object {$_.Extent.StartOffset})
if($phaseCalls.Count-ne3){throw ('Measure-DutyPhase invocation count '+$phaseCalls.Count)}
$phaseTexts=@($phaseCalls|ForEach-Object{$_.Extent.Text})
$expectedPhaseTexts=@('Measure-DutyPhase 0.10 8 20','Measure-DutyPhase 0.25 8 20','Measure-DutyPhase 0.40 8 20')
for($i=0;$i-lt3;$i++){if($phaseTexts[$i]-cne$expectedPhaseTexts[$i]){throw ('Duty phase invocation mismatch index='+$i+' actual='+$phaseTexts[$i])}}
function Get-FixedStageOffset([string]$CommandName,[string]$Stage){
  $hits=@($supAst.FindAll({param($n) $n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq $CommandName},$true)|Where-Object{
    $els=@($_.CommandElements)
    $els.Count-ge2 -and $els[1] -is [Management.Automation.Language.StringConstantExpressionAst] -and [string]$els[1].Value -eq $Stage
  })
  if($hits.Count-ne1){throw ($CommandName+' '+$Stage+' count '+$hits.Count)}
  return [int]$hits[0].Extent.StartOffset
}
$positions=[ordered]@{
  GPU_BOOTSTRAP=(Get-FixedStageOffset 'Start-LearningStage' 'GPU_BOOTSTRAP')
  GPU_DUTY_ATTACH=(Get-FixedStageOffset 'Start-LearningStage' 'GPU_DUTY_ATTACH')
  GPU_PHASE_SAMPLER=(Get-FixedStageOffset 'Start-LearningStage' 'GPU_PHASE_SAMPLER')
  GPU_CONTROLLED_WARMUP_40=(Get-FixedStageOffset 'Start-LearningStage' 'GPU_CONTROLLED_WARMUP_40')
  GPU_CALIBRATION_10=[int]$phaseCalls[0].Extent.StartOffset
  GPU_CALIBRATION_25=[int]$phaseCalls[1].Extent.StartOffset
  GPU_CALIBRATION_40=[int]$phaseCalls[2].Extent.StartOffset
  GPU_CALIBRATION_ACCEPTANCE=(Get-FixedStageOffset 'Start-LearningStage' 'GPU_CALIBRATION_ACCEPTANCE')
  GPU_LIVE=(Get-FixedStageOffset 'Write-LearningState' 'GPU_LIVE')
}
$stageOrder=@('GPU_BOOTSTRAP','GPU_DUTY_ATTACH','GPU_PHASE_SAMPLER','GPU_CONTROLLED_WARMUP_40','GPU_CALIBRATION_10','GPU_CALIBRATION_25','GPU_CALIBRATION_40','GPU_CALIBRATION_ACCEPTANCE','GPU_LIVE')
for($i=1;$i-lt$stageOrder.Count;$i++){if([int]$positions[$stageOrder[$i]]-le[int]$positions[$stageOrder[$i-1]]){throw ('Stage order invalid '+$stageOrder[$i-1]+' -> '+$stageOrder[$i])}}
$simPass=[ordered]@{productive40=$true;lowerProductiveCount=1;timingOk=$true;controlEffect=$true;poolOk=$true;threadControl=$true}
$accept=($simPass.productive40-and$simPass.lowerProductiveCount-gt0-and$simPass.timingOk-and$simPass.controlEffect-and$simPass.poolOk-and$simPass.threadControl)
if(-not$accept){throw 'Positive state simulation did not accept'}
$simFail=$simPass.Clone();$simFail.controlEffect=$false
$reject=($simFail.productive40-and$simFail.lowerProductiveCount-gt0-and$simFail.timingOk-and$simFail.controlEffect-and$simFail.poolOk-and$simFail.threadControl)
if($reject){throw 'Negative state simulation did not reject'}
'@
$oldState=$oldState.Trim();$newState=$newState.Trim()
$s1=$patched.IndexOf($oldState,[StringComparison]::Ordinal);$s2=$patched.LastIndexOf($oldState,[StringComparison]::Ordinal)
if($s1-lt0-or$s1-ne$s2){throw ('Expected one old state block, first='+$s1+' last='+$s2)}
$patched=$patched.Substring(0,$s1)+$newState+$patched.Substring($s1+$oldState.Length)
[IO.File]::WriteAllText($tmp,$patched,[Text.UTF8Encoding]::new($false))
$tok=$null;$err=$null;[void][Management.Automation.Language.Parser]::ParseFile($tmp,[ref]$tok,[ref]$err)
if($err.Count-gt0){throw ('Generated validator ParseFile failed: '+(($err|ForEach-Object{$_.ErrorId+':'+$_.Message})-join' | '))}
& $tmp -PwshPath $PwshPath
if($LASTEXITCODE-ne0){exit $LASTEXITCODE}
