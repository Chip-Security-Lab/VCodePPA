//SystemVerilog
module int_ctrl_secure #(
    parameter DOMAINS = 2
)(
    input clk, rst,
    input [DOMAINS-1:0] domain_en,
    input [15:0] intr_vec,
    output reg [3:0] secure_grant
);
    // 明确的位宽扩展
    wire [15:0] domain_mask;
    assign domain_mask = {16{|domain_en}};
    wire [15:0] masked_intr = intr_vec & domain_mask;
    
    // 中间寄存器，用于消除encoder高扇出问题
    reg [15:0] masked_intr_reg;
    
    // 将masked_intr输入寄存一级，减少扇出负载
    always @(posedge clk) begin
        masked_intr_reg <= masked_intr;
    end
    
    // 编码器输出信号
    wire [3:0] encoder_out;
    
    // 分组编码器逻辑，将高扇出信号分解为多级，减少关键路径延迟
    // 分为高8位和低8位分别处理
    wire [3:0] encoder_high, encoder_low;
    wire high_valid, low_valid;
    
    // 高8位编码器
    assign high_valid = |masked_intr_reg[15:8];
    assign encoder_high = masked_intr_reg[15] ? 4'd15 :
                          masked_intr_reg[14] ? 4'd14 :
                          masked_intr_reg[13] ? 4'd13 :
                          masked_intr_reg[12] ? 4'd12 :
                          masked_intr_reg[11] ? 4'd11 :
                          masked_intr_reg[10] ? 4'd10 :
                          masked_intr_reg[9]  ? 4'd9  :
                          masked_intr_reg[8]  ? 4'd8  : 4'd0;
    
    // 低8位编码器
    assign low_valid = |masked_intr_reg[7:0];
    assign encoder_low = masked_intr_reg[7] ? 4'd7 :
                         masked_intr_reg[6] ? 4'd6 :
                         masked_intr_reg[5] ? 4'd5 :
                         masked_intr_reg[4] ? 4'd4 :
                         masked_intr_reg[3] ? 4'd3 :
                         masked_intr_reg[2] ? 4'd2 :
                         masked_intr_reg[1] ? 4'd1 :
                         masked_intr_reg[0] ? 4'd0 : 4'd0;
    
    // 合并编码结果
    assign encoder_out = high_valid ? encoder_high : 
                        (low_valid ? encoder_low : 4'd0);
    
    // 输出寄存器
    always @(posedge clk) begin
        secure_grant <= encoder_out;
    end
endmodule