//SystemVerilog
module config_polarity_rst_sync (
    input  wire clk,
    input  wire reset_in,
    input  wire active_high,
    output wire sync_reset
);
    // 内部连线
    wire normalized_reset;
    wire sync_out;
    reg active_high_reg;
    
    // 缓存配置信号
    always @(posedge clk) begin
        active_high_reg <= active_high;
    end
    
    // 实例化优化后的组合逻辑和同步模块
    optimized_reset_sync reset_sync_inst (
        .clk            (clk),
        .reset_in       (reset_in),
        .active_high    (active_high),
        .active_high_reg(active_high_reg),
        .sync_reset     (sync_reset)
    );
endmodule

// 优化后的复位同步器模块（合并了转换和同步功能）
module optimized_reset_sync (
    input  wire clk,
    input  wire reset_in,
    input  wire active_high,
    input  wire active_high_reg,
    output wire sync_reset
);
    // 寄存器声明
    reg input_normalized;
    reg [1:0] sync_chain_reg;
    
    // 输入极性转换
    always @(posedge clk) begin
        input_normalized <= active_high ? reset_in : !reset_in;
    end
    
    // 同步链
    always @(posedge clk) begin
        sync_chain_reg <= {sync_chain_reg[0], input_normalized};
    end
    
    // 输出极性转换 - 寄存器被移动到组合逻辑之前
    assign sync_reset = active_high_reg ? sync_chain_reg[1] : !sync_chain_reg[1];
endmodule

// 保留原始模块以维护接口兼容性，但不再使用
module reset_polarity_converter (
    input  wire reset_in,
    input  wire active_high,
    output wire normalized_out
);
    assign normalized_out = active_high ? reset_in : !reset_in;
endmodule

module reset_synchronizer (
    input  wire clk,
    input  wire async_reset_in,
    output wire sync_reset_out
);
    reg [1:0] sync_chain_reg;
    
    always @(posedge clk) begin
        sync_chain_reg <= {sync_chain_reg[0], async_reset_in};
    end
    
    assign sync_reset_out = sync_chain_reg[1];
endmodule