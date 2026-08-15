param([Parameter(Mandatory)][string]$PwshPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$outDir=Join-Path $PSScriptRoot 'diag_out';New-Item -ItemType Directory -Force -Path $outDir|Out-Null
$partsDir=Join-Path $PSScriptRoot 'rc16_exact_parts'
$parts=@(Get-ChildItem -LiteralPath $partsDir -File -Filter 'part*.txt'|Sort-Object Name)
if($parts.Count-ne5){throw ('Expected 5 parts, found '+$parts.Count)}
$ms=[IO.MemoryStream]::new();try{foreach($p in $parts){$bytes=[IO.File]::ReadAllBytes($p.FullName);$ms.Write($bytes,0,$bytes.Length)};$bytes=$ms.ToArray()}finally{$ms.Dispose()}
$path=Join-Path $outDir 'RECONSTRUCTED_60141.ps1';[IO.File]::WriteAllBytes($path,$bytes)
$sha=(Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant();if($sha-ne'60141bc4647121b14fe5b39bdeb0ae922ec0937b204fea382af0e36153caef76'){throw ('SHA mismatch '+$sha)}
$t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$t,[ref]$e)
$all=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$script:ExportPayload'},$true))
$result=[ordered]@{status='PASS';source_sha256=$sha;parse_error_count=$e.Count;assignment_count=$all.Count;assignments=@()}
$i=0
foreach($a in $all){
  $i++
  $parents=[Collections.Generic.List[string]]::new();$p=$a.Parent;$depth=0
  while($null-ne$p-and$depth-lt10){$parents.Add($p.GetType().FullName);$p=$p.Parent;$depth++}
  $rhs=$a.Right;$rhsType=$rhs.GetType().FullName;$innerType=$null
  if($rhs -is [Management.Automation.Language.CommandExpressionAst] -and $null-ne$rhs.Expression){$innerType=$rhs.Expression.GetType().FullName}
  $extent=[string]$a.Extent.Text
  $preview=if($extent.Length-gt500){$extent.Substring(0,500)}else{$extent}
  $result.assignments += [ordered]@{
    index=$i;start_offset=$a.Extent.StartOffset;end_offset=$a.Extent.EndOffset;start_line=$a.Extent.StartLineNumber;start_column=$a.Extent.StartColumnNumber;end_line=$a.Extent.EndLineNumber;end_column=$a.Extent.EndColumnNumber;rhs_type=$rhsType;rhs_inner_type=$innerType;parent_chain=@($parents);extent_preview=$preview
  }
}
$result|ConvertTo-Json -Depth 20|Set-Content -LiteralPath (Join-Path $outDir 'EXPORTPAYLOAD_AST_DIAGNOSTIC.json') -Encoding utf8
Write-Host ('EXPORTPAYLOAD_AST_DIAGNOSTIC_PASS count='+$all.Count+' parse_errors='+$e.Count)
