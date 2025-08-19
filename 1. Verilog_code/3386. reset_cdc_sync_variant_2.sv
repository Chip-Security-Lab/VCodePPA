//SystemVerilog
// Top-level module for reset CDC synchronization
module reset_cdc_sync (
    input  wire dst_clk,
    input  wire async_rst_in,
    output wire synced_rst
);
    // 内部连接信号
    wire meta_stage_out;
    
    // 实例化亚稳态捕获子模块
    reset_metastability_capture meta_stage (
        .dst_clk      (dst_clk),
        .async_rst_in (async_rst_in),
        .meta_out     (meta_stage_out)
    );
    
    // 实例化输出同步子模块
    reset_output_synchronizer output_stage (
        .dst_clk      (dst_clk),
        .async_rst_in (async_rst_in),
        .meta_in      (meta_stage_out),
        .synced_rst   (synced_rst)
    );
    
endmodule

// Metastability capture module for first synchronization stage
module reset_metastability_capture (
    input  wire dst_clk,
    input  wire async_rst_in,
    output reg  meta_out
);
    // 捕获异步复位并在时钟域内同步 - 第一级亚稳态处理
    always @(posedge dst_clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            meta_out <= 1'b1;
        end else begin
            meta_out <= 1'b0;
        end
    end
endmodule

// Output synchronization module for final stage processing
module reset_output_synchronizer (
    input  wire dst_clk,
    input  wire async_rst_in,
    input  wire meta_in,
    output reg  synced_rst
);
    // 内部寄存器用于额外同步级
    reg output_stage;
    
    // 处理输出同步 - 第二级同步和输出处理
    always @(posedge dst_clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            output_stage <= 1'b1;
            synced_rst <= 1'b1;
        end else begin
            output_stage <= meta_in;
            synced_rst <= output_stage;
        end
    end
endmodule