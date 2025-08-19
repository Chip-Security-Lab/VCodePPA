//SystemVerilog
module final_xor_crc16(
    input wire clk,
    input wire reset,
    input wire [7:0] data,
    input wire data_valid,
    input wire calc_done,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h1021;
    parameter [15:0] FINAL_XOR = 16'hFFFF;
    
    reg [15:0] crc_reg;
    wire crc_feedback;
    
    // 使用专用的反馈信号以减少关键路径延迟
    assign crc_feedback = crc_reg[15] ^ data[0];
    
    always @(posedge clk) begin
        if (reset) begin
            crc_reg <= 16'h0000;
            crc_out <= 16'h0000;
        end else if (data_valid) begin
            // 优化了比较逻辑，避免使用条件运算符
            // 直接用位操作替代条件表达式，减少逻辑层次
            crc_reg <= {crc_reg[14:0], 1'b0} ^ ({16{crc_feedback}} & POLY);
        end else if (calc_done) begin
            crc_out <= crc_reg ^ FINAL_XOR;
        end
    end
endmodule