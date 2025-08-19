//SystemVerilog
module multi_context_regfile #(
    parameter DW = 32,
    parameter AW = 3,
    parameter CTX_BITS = 3
)(
    input clk,
    input rst_n,  // 添加复位信号
    input [CTX_BITS-1:0] ctx_sel,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    input valid_in,  // 输入有效信号
    output valid_out, // 输出有效信号
    output [DW-1:0] dout
);
    // 存储块 - 8个上下文
    reg [DW-1:0] ctx_bank [0:7][0:(1<<AW)-1];
    
    // 流水线寄存器
    reg [CTX_BITS-1:0] ctx_sel_stage1;
    reg [AW-1:0] addr_stage1;
    reg [DW-1:0] din_stage1;
    reg wr_en_stage1;
    reg valid_stage1;
    
    reg [DW-1:0] dout_stage2;
    reg valid_stage2;
    
    // 第一级流水线：寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctx_sel_stage1 <= 0;
            addr_stage1 <= 0;
            din_stage1 <= 0;
            wr_en_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            ctx_sel_stage1 <= ctx_sel;
            addr_stage1 <= addr;
            din_stage1 <= din;
            wr_en_stage1 <= wr_en;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：执行读写操作并寄存输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            // 读操作在每个周期进行
            dout_stage2 <= ctx_bank[ctx_sel_stage1][addr_stage1];
            valid_stage2 <= valid_stage1;
            
            // 写操作
            if (wr_en_stage1 && valid_stage1) begin
                ctx_bank[ctx_sel_stage1][addr_stage1] <= din_stage1;
            end
        end
    end
    
    // 输出赋值
    assign dout = dout_stage2;
    assign valid_out = valid_stage2;
    
endmodule