$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$outDir=Join-Path $PSScriptRoot 'payload_inventory_out';New-Item -ItemType Directory -Force -Path $outDir|Out-Null
$parts=@(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'rc16_exact_parts') -File -Filter 'part*.txt'|Sort-Object Name)
if($parts.Count-ne5){throw ('Expected 5 parts, got '+$parts.Count)}
$ms=[IO.MemoryStream]::new();try{foreach($p in $parts){$b=[IO.File]::ReadAllBytes($p.FullName);$ms.Write($b,0,$b.Length)};$bytes=$ms.ToArray()}finally{$ms.Dispose()}
$src=Join-Path $outDir 'RECONSTRUCTED_60141.ps1';[IO.File]::WriteAllBytes($src,$bytes)
$sha=(Get-FileHash -Algorithm SHA256 -LiteralPath $src).Hash.ToLowerInvariant();if($sha-ne'60141bc4647121b14fe5b39bdeb0ae922ec0937b204fea382af0e36153caef76'){throw ('SHA mismatch '+$sha)}
$t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($src,[ref]$t,[ref]$e)
$names=@('LearningModulePayload','SupervisorPayload','DutyFixturePayload','StopPayload','StatusPayload','ExportPayload')
$res=[ordered]@{status='PASS';source_sha256=$sha;parse_error_count=$e.Count;payloads=[ordered]@{}}
foreach($name in $names){
  $nodes=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq ('$script:'+$name)},$true)|Sort-Object {$_.Extent.StartOffset})
  $items=@();$i=0
  foreach($a in $nodes){$i++;$rhs=$a.Right;$inner=$null;if($rhs -is [Management.Automation.Language.CommandExpressionAst] -and $null-ne$rhs.Expression){$inner=$rhs.Expression.GetType().FullName};$pv=[string]$a.Extent.Text;if($pv.Length-gt260){$pv=$pv.Substring(0,260)};$items += [ordered]@{index=$i;start_offset=$a.Extent.StartOffset;end_offset=$a.Extent.EndOffset;start_line=$a.Extent.StartLineNumber;end_line=$a.Extent.EndLineNumber;rhs_type=$rhs.GetType().FullName;rhs_inner_type=$inner;parent_type=$a.Parent.GetType().FullName;grandparent_type=if($a.Parent.Parent){$a.Parent.Parent.GetType().FullName}else{$null};preview=$pv}}
  $res.payloads[$name]=[ordered]@{count=$nodes.Count;assignments=$items}
}
$res|ConvertTo-Json -Depth 30|Set-Content -LiteralPath (Join-Path $outDir 'ALL_PAYLOAD_ASSIGNMENTS.json') -Encoding utf8
Write-Host ('ALL_PAYLOAD_ASSIGNMENTS_PASS '+(($names|ForEach-Object{$_+'='+$res.payloads[$_].count})-join' '))
