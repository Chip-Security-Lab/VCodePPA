//SystemVerilog
// 顶层模块
module multi_route_xnor1 (
    input  wire A, B, C,
    output wire Y
);
    // 由于XNOR的特性，三个输入全相同或全不同时，三个XNOR的结果都为1
    // 使用布尔代数简化：当且仅当三个输入全相同(全0或全1)或全不同时，输出为1
    assign Y = (~A & ~B & ~C) | (A & B & C) | (A & ~B & ~C) | (~A & B & C);
    
    // 等效实现 - 使用逻辑式直接判断相等性
    // assign Y = ((A == B) && (B == C)) || ((A != B) && (B != C) && (A != C));
endmodule