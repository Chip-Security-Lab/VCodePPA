//SystemVerilog
module clk_gate_async_rst #(parameter INIT=0) (
    input clk, rst_n, en,
    output reg q
);
    // 内部流水线寄存器
    wire en_stage1, en_stage2;
    wire toggle_stage1, toggle_stage2, toggle_stage3;
    
    // 创建流水线寄存器实例
    async_reset_reg #(.INIT(1'b0)) en_reg1 (
        .clk(clk),
        .rst_n(rst_n),
        .d(en),
        .en(1'b1),
        .q(en_stage1)
    );
    
    async_reset_reg #(.INIT(1'b0)) en_reg2 (
        .clk(clk),
        .rst_n(rst_n),
        .d(en_stage1),
        .en(1'b1),
        .q(en_stage2)
    );
    
    async_reset_reg #(.INIT(1'b0)) toggle_reg1 (
        .clk(clk),
        .rst_n(rst_n),
        .d(en_stage2),
        .en(1'b1),
        .q(toggle_stage1)
    );
    
    async_reset_reg #(.INIT(1'b0)) toggle_reg2 (
        .clk(clk),
        .rst_n(rst_n),
        .d(toggle_stage1 ? ~q : 1'b0),
        .en(1'b1),
        .q(toggle_stage2)
    );
    
    async_reset_reg #(.INIT(1'b0)) toggle_reg3 (
        .clk(clk),
        .rst_n(rst_n),
        .d(toggle_stage1 ? 1'b1 : 1'b0),
        .en(1'b1),
        .q(toggle_stage3)
    );
    
    // 流水线输出级：使用带使能的寄存器
    async_reset_reg #(.INIT(INIT)) q_reg (
        .clk(clk),
        .rst_n(rst_n),
        .d(toggle_stage2 ? 1'b1 : 1'b0),
        .en(toggle_stage3),
        .q(q)
    );
endmodule

// 可复用的异步复位寄存器模块
module async_reset_reg #(
    parameter INIT = 1'b0
)(
    input clk,
    input rst_n,
    input d,
    input en,
    output reg q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= INIT;
        end else if (en) begin
            q <= d;
        end
    end
endmodule