//SystemVerilog
// 顶层模块 - 时钟门控控制器
module clock_gate (
    input  wire clk,
    input  wire enable,
    output wire gated_clk
);
    // 内部信号定义
    wire enable_latched;
    wire enable_sync;
    wire enable_valid;
    
    // 使能信号同步和验证模块
    enable_sync_unit u_enable_sync (
        .clk(clk),
        .enable(enable),
        .enable_sync(enable_sync),
        .enable_valid(enable_valid)
    );
    
    // 时钟门控生成模块
    clock_gate_gen u_clock_gate_gen (
        .clk(clk),
        .enable_sync(enable_sync),
        .enable_valid(enable_valid),
        .gated_clk(gated_clk)
    );
    
endmodule

// 使能信号同步和验证模块
module enable_sync_unit (
    input  wire clk,
    input  wire enable,
    output reg  enable_sync,
    output reg  enable_valid
);
    // 同步寄存器
    reg enable_meta;
    reg enable_sync_ff;
    
    // 同步逻辑
    always @(posedge clk) begin
        enable_meta <= enable;
        enable_sync_ff <= enable_meta;
        enable_sync <= enable_sync_ff;
    end
    
    // 使能信号有效性检测
    always @(posedge clk) begin
        enable_valid <= (enable_sync == enable_sync_ff);
    end
    
endmodule

// 时钟门控生成模块
module clock_gate_gen (
    input  wire clk,
    input  wire enable_sync,
    input  wire enable_valid,
    output wire gated_clk
);
    // 时钟门控逻辑
    reg gated_clk_reg;
    
    // 时钟门控生成逻辑
    always @(posedge clk) begin
        if (enable_valid) begin
            gated_clk_reg <= enable_sync;
        end
    end
    
    // 时钟输出
    assign gated_clk = clk & gated_clk_reg;
    
endmodule