#!/usr/bin/env python3
from pathlib import Path
import sys, hashlib

src=Path(sys.argv[1]).read_text(encoding='utf-8')
# Identity-only replacements first.
s=(src.replace('GPU_LANE_R065_RC17','GPU_LANE_R065_RC18')
       .replace('R065_RC17','R065_RC18')
       .replace('GPU RC17','GPU RC18')
       .replace('RC17','RC18')
       .replace('0.65.2-gpu-rc17','0.65.3-gpu-rc18')
       .replace('0.65.2','0.65.3'))
# Remove CPU-specific helper block exactly from Get-XmrigApi through Assert-CpuRc6LoopLiveness.
start=s.index("function Get-XmrigApi([int]$Port)")
end=s.index("try{\n  if($learningBaseMissingAtStart)", start)
s=s[:start]+s[end:]
# Remove the blocking CPU preflight stage exactly.
start=s.index("  $currentMainLearningStage='CPU_RC6_COEXISTENCE_PRE'")
end=s.index("  $currentMainLearningStage='NVIDIA_TELEMETRY_PRECHECK'", start)
s=s[:start]+"  # GPU lane is independent: CPU lane health is intentionally not a blocking prerequisite.\n\n"+s[end:]
# Remove the blocking CPU postflight stage exactly.
start=s.index("  $currentMainLearningStage='CPU_RC6_COEXISTENCE_POST'")
end=s.index("  $activation.cpu_rc6_untouched=$true", start)
s=s[:start]+"  # CPU lane is independent and is neither inspected nor modified by this GPU activation.\n"+s[end:]
# Rewrite final success semantics to avoid claiming CPU liveness.
s=s.replace("GPU R065 RC18 completed exact duty fixture, calibrated 10/25/40 and entered live mode while CPU RC6 remained independent.",
            "GPU R065 RC18 completed exact duty fixture, calibrated 10/25/40 and entered live mode. CPU lane was not used as a prerequisite and was not modified.")
s=s.replace("@{learning_store='PASS';cpu_rc6='PASS_UNTOUCHED';gpu_live='PASS';duty_control_surface='PASS'}",
            "@{learning_store='PASS';cpu_lane='INDEPENDENT_NOT_CHECKED_OR_MODIFIED';gpu_live='PASS';duty_control_surface='PASS'}")
out=Path(sys.argv[2])
out.write_text(s,encoding='utf-8',newline='')
print(hashlib.sha256(out.read_bytes()).hexdigest())
