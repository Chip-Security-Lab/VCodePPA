//SystemVerilog
// 顶层模块
module latch_based_clock_gate (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // 内部连线
    wire enable_latched;
    
    // 实例化子模块
    enable_latch_stage u_enable_latch (
        .clk_in(clk_in),
        .enable(enable),
        .latch_out(enable_latched)
    );
    
    gating_logic_stage u_gating_logic (
        .clk_in(clk_in),
        .enable_latched(enable_latched),
        .clk_out(clk_out)
    );
    
endmodule

// 第一子模块：使能信号锁存阶段
module enable_latch_stage (
    input  wire clk_in,
    input  wire enable,
    output wire latch_out
);
    (* keep = "true" *) reg latch_q;
    
    always @(negedge clk_in) begin
        latch_q <= enable;
    end
    
    assign latch_out = latch_q;
endmodule

// 第二子模块：时钟门控逻辑阶段
module gating_logic_stage (
    input  wire clk_in,
    input  wire enable_latched,
    output wire clk_out
);
    // 时钟门控逻辑实现
    assign clk_out = clk_in & enable_latched;
endmodule