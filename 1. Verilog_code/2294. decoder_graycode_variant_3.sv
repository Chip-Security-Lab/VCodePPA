//SystemVerilog
module decoder_graycode #(parameter AW=4) (
    input [AW-1:0] bin_addr,
    output [2**AW-1:0] decoded
);
    wire [AW-1:0] gray_addr;
    wire [2**AW-1:0] mux_out[AW:0];
    reg [7:0] diff_result;
    reg [7:0] lut_diff [0:255][0:255];
    reg [7:0] operand_a, operand_b;
    
    // 二进制转格雷码
    assign gray_addr = bin_addr ^ (bin_addr >> 1);
    
    // 桶形移位器初始值 - 第0级为1'b1
    assign mux_out[0] = 1'b1;
    
    // 查找表初始化 - 用于辅助减法运算
    integer i, j;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                lut_diff[i][j] = i - j;
            end
        end
    end
    
    // 使用查找表进行减法运算
    always @(*) begin
        operand_a = {4'b0000, gray_addr};
        operand_b = {4'b0000, bin_addr};
        diff_result = lut_diff[operand_a][operand_b];
    end
    
    // 桶形移位器实现 - 基于查找表辅助算法
    genvar k;
    generate
        for (k = 0; k < AW; k = k + 1) begin : barrel_shifter_stage
            wire shift_ctrl = gray_addr[k] & (diff_result != 8'b0);
            assign mux_out[k+1] = shift_ctrl ? 
                                 {mux_out[k][2**(AW-1)-1:0], mux_out[k][2**AW-1:2**(AW-1)]} : 
                                 mux_out[k];
        end
    endgenerate
    
    // 输出最终移位结果
    assign decoded = mux_out[AW];
endmodule