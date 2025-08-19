//SystemVerilog
module async_hamming_decoder(
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [11:0] encoded_in,
    output valid_out,
    input ready_in,
    output [7:0] data_out,
    output single_err, double_err
);
    reg [11:0] encoded_reg;
    reg valid_reg;
    wire [3:0] syndrome;
    wire parity_check;
    
    // 简化Valid-Ready握手逻辑
    assign ready_out = ready_in | ~valid_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_reg <= 12'b0;
            valid_reg <= 1'b0;
        end else if (valid_in && (ready_in || ~valid_reg)) begin
            encoded_reg <= encoded_in;
            valid_reg <= 1'b1;
        end else if (ready_in) begin
            valid_reg <= 1'b0;
        end
    end
    
    assign valid_out = valid_reg;
    
    // 优化汉明解码器逻辑
    // 使用简化的布尔表达式计算校验位
    assign syndrome[0] = encoded_reg[0] ^ (encoded_reg[2] ^ encoded_reg[4] ^ encoded_reg[6] ^ encoded_reg[8] ^ encoded_reg[10]);
    assign syndrome[1] = encoded_reg[1] ^ (encoded_reg[2] ^ encoded_reg[5] ^ encoded_reg[6] ^ encoded_reg[9] ^ encoded_reg[10]);
    assign syndrome[2] = encoded_reg[3] ^ encoded_reg[4] ^ encoded_reg[5] ^ encoded_reg[6];
    assign syndrome[3] = encoded_reg[7] ^ encoded_reg[8] ^ encoded_reg[9] ^ encoded_reg[10];
    
    // 使用reduction XOR操作符直接计算奇偶校验
    assign parity_check = ^encoded_reg;
    
    // 简化错误检测逻辑
    wire syndrome_nonzero;
    assign syndrome_nonzero = |syndrome;
    assign single_err = syndrome_nonzero & ~parity_check;
    assign double_err = syndrome_nonzero & parity_check;
    
    // 直接组合数据输出以减少逻辑层级
    assign data_out = {encoded_reg[10:7], encoded_reg[6:4], encoded_reg[2]};
endmodule