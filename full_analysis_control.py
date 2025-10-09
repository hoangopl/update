# full_analysis_control.py
# Usage:  full_analysis_control.py <base> <end>
# Mục tiêu: bật toàn bộ analyzer mặc định trừ 3 cái cụ thể

from ghidra.program.util import GhidraProgramUtilities
from ghidra.app.script import GhidraScript
from ghidra.app.services import AnalyzerService

class RunFullAnalysis(GhidraScript):
    def run(self):
        args = self.getScriptArgs()
        base_addr = int(args[0], 16) if len(args) > 0 else 0
        end_addr = int(args[1], 16) if len(args) > 1 else 0

        # Đặt base address nếu cần
        currentProgram.getImageBase().setOffset(base_addr)
        GhidraProgramUtilities.markProgramChanged(currentProgram)

        aservice = state.getTool().getService(AnalyzerService)
        if aservice is None:
            print("[!] Không thể lấy AnalyzerService – có thể đang chạy headless cũ.")
        else:
            for analyzer in aservice.getAnalyzers(currentProgram):
                name = analyzer.getName()
                # Tắt 3 cái bạn yêu cầu
                if name in [
                    "Aggressive Instruction Finder (Prototype)",
                    "Condense Filler Bytes (Prototype)",
                    "Variadic Function Signature Override"
                ]:
                    analyzer.setEnabled(False)
                    print("[−] Disabled:", name)
                else:
                    analyzer.setEnabled(True)
                    print("[+] Enabled:", name)

        # Chạy full analyze
        print("[*] Running analysis...")
        analyzeAll(currentProgram)
        print("[✓] Done")

RunFullAnalysis().run()