//SystemVerilog
//===================================================================
// 顶层模块 - basic_d_latch
//===================================================================
module basic_d_latch (
    input  wire d,
    input  wire enable,
    output wire q
);
    // 内部连线
    wire data_signal;
    
    // 数据处理子模块
    data_conditioning data_unit (
        .data_in(d),
        .data_out(data_signal)
    );
    
    // 锁存控制子模块
    latch_control latch_unit (
        .data_in(data_signal),
        .enable(enable),
        .q_out(q)
    );
    
endmodule

//===================================================================
// 数据处理子模块
//===================================================================
module data_conditioning (
    input  wire data_in,
    output wire data_out
);
    // 简单的数据缓冲，可扩展为数据预处理
    assign data_out = data_in;
    
endmodule

//===================================================================
// 锁存控制子模块
//===================================================================
module latch_control (
    input  wire data_in,
    input  wire enable,
    output reg  q_out
);
    // 锁存器逻辑
    always @* begin
        if (enable)
            q_out = data_in;
    end
    
endmodule