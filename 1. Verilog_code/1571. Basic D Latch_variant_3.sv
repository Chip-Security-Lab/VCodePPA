//SystemVerilog
// 顶层模块
module basic_d_latch (
    input  wire d,
    input  wire enable,
    output wire q
);
    // 内部信号
    wire d_buffered;
    wire enable_buffered;
    wire q_internal;
    
    // 实例化输入缓冲子模块
    input_buffer input_buff_inst (
        .d_in(d),
        .enable_in(enable),
        .d_out(d_buffered),
        .enable_out(enable_buffered)
    );
    
    // 实例化核心锁存器逻辑子模块
    latch_core latch_core_inst (
        .d(d_buffered),
        .enable(enable_buffered),
        .q(q_internal)
    );
    
    // 实例化输出缓冲子模块
    output_buffer output_buff_inst (
        .q_in(q_internal),
        .q_out(q)
    );
    
endmodule

// 输入缓冲子模块
module input_buffer (
    input  wire d_in,
    input  wire enable_in,
    output wire d_out,
    output wire enable_out
);
    // 输入缓冲器以减少输入负载并改善时序
    assign d_out = d_in;
    assign enable_out = enable_in;
endmodule

// 核心锁存器逻辑子模块
module latch_core (
    input  wire d,
    input  wire enable,
    output reg  q
);
    // 核心锁存功能
    always @* begin
        if (enable)
            q = d;
    end
endmodule

// 输出缓冲子模块
module output_buffer (
    input  wire q_in,
    output wire q_out
);
    // 输出缓冲以提供良好的驱动能力
    assign q_out = q_in;
endmodule