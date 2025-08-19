//SystemVerilog
module basic_d_latch (
    input wire d,
    input wire enable,
    output wire q
);
    // 控制信号
    wire enable_buffered;
    wire d_buffered;
    wire q_internal;
    
    // 实例化输入缓冲子模块
    input_buffer input_buff_inst (
        .d_in(d),
        .enable_in(enable),
        .d_out(d_buffered),
        .enable_out(enable_buffered)
    );
    
    // 实例化锁存器核心逻辑子模块
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

module input_buffer (
    input wire d_in,
    input wire enable_in,
    output reg d_out,
    output reg enable_out
);
    // 输入信号缓冲，减少输入负载，提高驱动能力
    always @* begin
        d_out = d_in;
        enable_out = enable_in;
    end
endmodule

module latch_core (
    input wire d,
    input wire enable,
    output reg q
);
    // 核心锁存器逻辑
    always @* begin
        if (enable)
            q = d;
    end
endmodule

module output_buffer (
    input wire q_in,
    output reg q_out
);
    // 输出信号缓冲，提高驱动能力
    always @* begin
        q_out = q_in;
    end
endmodule