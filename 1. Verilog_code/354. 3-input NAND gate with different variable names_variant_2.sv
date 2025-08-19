//SystemVerilog
//-----------------------------------------------------------------
// Module: nand3_2
// Description: 优化的三输入NAND门实现，采用层次化设计
//-----------------------------------------------------------------
module nand3_2 #(
    parameter DELAY_OPTIMIZE = 1  // 参数化设计，1表示优化延迟，0表示标准实现
)(
    input  wire X,
    input  wire Y, 
    input  wire Z,
    output wire F
);

    // 两种实现策略
    generate
        if (DELAY_OPTIMIZE) begin : gen_optimized
            // 优化版本：直接实现NAND逻辑，减少门延迟
            nand3_direct_module nand_gate (
                .in_x(X),
                .in_y(Y),
                .in_z(Z),
                .out_f(F)
            );
        end else begin : gen_standard
            // 标准版本：通过AND+NOT实现
            wire and_result;
            
            and3_module and_gate (
                .a(X),
                .b(Y),
                .c(Z),
                .result(and_result)
            );
            
            inverter_module inv_gate (
                .in(and_result),
                .out(F)
            );
        end
    endgenerate
    
endmodule

//-----------------------------------------------------------------
// Module: nand3_direct_module
// Description: 直接实现三输入NAND门，减少延迟
//-----------------------------------------------------------------
module nand3_direct_module (
    input  wire in_x,
    input  wire in_y,
    input  wire in_z,
    output wire out_f
);
    // 直接NAND实现，优化路径延迟
    assign out_f = ~(in_x & in_y & in_z);
endmodule

//-----------------------------------------------------------------
// Module: and3_module
// Description: 三输入与门子模块
//-----------------------------------------------------------------
module and3_module (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire result
);
    // 实现三输入与操作
    assign result = a & b & c;
endmodule

//-----------------------------------------------------------------
// Module: inverter_module
// Description: 反相器子模块
//-----------------------------------------------------------------
module inverter_module (
    input  wire in,
    output wire out
);
    // 实现反相操作
    assign out = ~in;
endmodule