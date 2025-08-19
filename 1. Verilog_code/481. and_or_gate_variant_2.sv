//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File Name: and_or_gate_top.v
// Description: Top level module for AND-OR gate logic structure
///////////////////////////////////////////////////////////////////////////////

module and_or_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 直接实现 Y = (A & B) | C 的逻辑，减少层级和延迟
    assign Y = (A & B) | C;
endmodule

///////////////////////////////////////////////////////////////////////////////
// File Name: and_operation.v
// Description: AND operation sub-module with improved implementation
///////////////////////////////////////////////////////////////////////////////

module and_operation (
    input wire a,
    input wire b,
    output wire y
);
    // 参数化设计，便于后续修改和优化
    parameter DELAY = 1;  // 延迟参数，便于时序优化
    
    // 实现AND逻辑
    assign #DELAY y = a & b;
endmodule

///////////////////////////////////////////////////////////////////////////////
// File Name: or_operation.v
// Description: OR operation sub-module with improved implementation
///////////////////////////////////////////////////////////////////////////////

module or_operation (
    input wire a,
    input wire b,
    output wire y
);
    // 参数化设计，便于后续修改和优化
    parameter DELAY = 1;  // 延迟参数，便于时序优化
    
    // 实现OR逻辑
    assign #DELAY y = a | b;
endmodule