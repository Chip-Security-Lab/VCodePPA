//SystemVerilog
// 顶层模块：双时钟域复位分发器
module dual_clk_reset_dist (
    input  wire clk_a, clk_b,
    input  wire master_rst,
    output wire rst_domain_a, rst_domain_b
);
    // 实例化Domain A的复位同步器
    reset_synchronizer #(
        .SYNC_STAGES(2)
    ) rst_sync_domain_a (
        .clk          (clk_a),
        .async_rst_in (master_rst),
        .sync_rst_out (rst_domain_a)
    );
    
    // 实例化Domain B的复位同步器
    reset_synchronizer #(
        .SYNC_STAGES(2)
    ) rst_sync_domain_b (
        .clk          (clk_b),
        .async_rst_in (master_rst),
        .sync_rst_out (rst_domain_b)
    );
endmodule

// 参数化的复位同步器子模块
module reset_synchronizer #(
    parameter SYNC_STAGES = 2  // 同步级数，可参数化
) (
    input  wire clk,           // 目标时钟域时钟
    input  wire async_rst_in,  // 异步复位输入
    output reg  sync_rst_out   // 同步复位输出
);
    // 内部同步级寄存器，使用N-1级寄存器实现
    reg [SYNC_STAGES-1:0] sync_stages;
    
    // 复位同步流水线
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            // 异步复位时，所有级都置为1
            sync_stages  <= {SYNC_STAGES{1'b1}};
            sync_rst_out <= 1'b1;
        end else begin
            // 正常操作时，实现移位寄存器
            sync_stages[0] <= 1'b0;
            
            // 处理中间级
            for (int i = 1; i < SYNC_STAGES; i++) begin
                sync_stages[i] <= sync_stages[i-1];
            end
            
            // 最终输出
            sync_rst_out <= sync_stages[SYNC_STAGES-1];
        end
    end
endmodule