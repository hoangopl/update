# find_il2cpp_regs.py
# Ghidra Jython script — paste vào Script Manager và chạy
# Mục tiêu: tìm il2cpp_codegen_register hoặc liệt kê các hàm *_il2cpp

from ghidra.program.model.symbol import RefType
from ghidra.util.task import TaskMonitor

monitor = TaskMonitor.DUMMY

program = currentProgram
listing = program.getListing()
symbolTable = program.getSymbolTable()
memory = program.getMemory()
fm = getFunctionManager()
decompiler = None
try:
    from ghidra.app.decompiler import DecompInterface
    decompiler = DecompInterface()
    decompiler.openProgram(program)
except:
    decompiler = None

def print_msg(s):
    print(s)

# 1) Tìm chuỗi "il2cpp_codegen_register" trong Defined Strings
found = False
data_iter = listing.getDefinedData(True)
print_msg("=== TÌM CHUỖI 'il2cpp_codegen_register' TRONG DEFINED STRINGS ===")
while data_iter.hasNext():
    d = data_iter.next()
    if d and d.getDataType() and d.getDataType().getName() == "string":
        text = str(d.getValue())
        if "il2cpp_codegen_register" in text:
            found = True
            addr = d.getAddress()
            print_msg("Tìm thấy chuỗi tại: %s   => '%s'" % (addr, text))
            # show references TO this string
            refs = getReferencesTo(addr)
            for r in refs:
                print_msg("  Xref from: %s (%s)" % (r.getFromAddress(), r.getReferenceType()))
if not found:
    print_msg("Không tìm thấy chuỗi 'il2cpp_codegen_register' trong strings.\n")

# 2) Nếu có symbol/function named il2cpp_codegen_register, tìm xrefs tới đó
print_msg("\n=== TÌM HÀM 'il2cpp_codegen_register' TRONG SYMBOL TABLE ===")
reg_funcs = []
for sym in symbolTable.getSymbols():
    name = sym.getName()
    if "il2cpp_codegen_register" in name:
        reg_funcs.append(sym)
        print_msg("Found symbol: %s @ %s" % (name, sym.getAddress()))
if reg_funcs:
    for sym in reg_funcs:
        refs = getReferencesTo(sym.getAddress())
        for r in refs:
            print_msg("  Call from %s (type %s)" % (r.getFromAddress(), r.getReferenceType()))
else:
    print_msg("Không thấy symbol 'il2cpp_codegen_register' trong symbol table.\n")

# 3) Nếu không có, liệt kê các hàm *_il2cpp hoặc functions có tên _start_il2cpp/_stop_il2cpp
print_msg("\n=== LIỆT KÊ HÀM CHỨA 'il2cpp' HOẶC '_start_il2cpp' / '_stop_il2cpp' ===")
candidates = []
for f in fm.getFunctions(True):
    n = f.getName()
    if "il2cpp" in n or "_start_il2cpp" in n or "_stop_il2cpp" in n:
        candidates.append(f)
        print_msg("Func: %s @ %s" % (n, f.getEntryPoint()))

if not candidates:
    print_msg("Không tìm thấy hàm tên chứa 'il2cpp' trực tiếp. Sẽ liệt kê 20 hàm gần .init_array nếu tồn tại.\n")
    # look for __init_array or .init_array region
    regions = memory.getRegions()
    init_addr = None
    for r in regions:
        if ".init" in r.getName() or "init_array" in r.getName():
            init_addr = r.getStart()
            break
    if init_addr:
        print_msg("Có vùng init tại %s — liệt kê 20 hàm bắt đầu từ đó:" % init_addr)
        funcs = fm.getFunctions(init_addr, True)
        cnt = 0
        for fn in funcs:
            print_msg("  %s @ %s" % (fn.getName(), fn.getEntryPoint()))
            cnt += 1
            if cnt >= 20:
                break
    else:
        print_msg("Không tìm thấy vùng init_array trong memory regions.\n")

# 4) Decompile candidates for quick inspection
if candidates:
    print_msg("\n=== DECOMPILE NHANH CÁC HÀM TÌM ĐƯỢC (SNIPPET) ===")
    for f in candidates:
        print_msg("\n--- Function %s @ %s ---" % (f.getName(), f.getEntryPoint()))
        if decompiler:
            res = decompiler.decompileFunction(f, 60, monitor)
            if res and res.decompiledFunction:
                src = res.getDecompiledFunction().getC()
                # chỉ in top 200 ký tự để không spam
                print_msg(src[:200])
            else:
                print_msg("Không decompile được (res None).")
        else:
            # fallback: in vài instruction đầu
            instructions = listing.getInstructions(f.getBody(), True)
            count = 0
            for ins in instructions:
                print_msg(str(ins))
                count += 1
                if count >= 20:
                    break

print_msg("\n=== XONG ===")
