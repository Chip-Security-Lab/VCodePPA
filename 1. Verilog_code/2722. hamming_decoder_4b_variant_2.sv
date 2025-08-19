//SystemVerilog
module hamming_decoder_4b(
    input clock, reset,
    input [6:0] code_in,
    output reg [3:0] data_out,
    output reg error_detected
);
    // 中间变量声明
    reg [2:0] syndrome;
    reg parity_bit0, parity_bit1, parity_bit2;
    reg data_bit0, data_bit1, data_bit2, data_bit3;
    
    always @(posedge clock) begin
        if (reset) begin
            // 复位逻辑
            data_out <= 4'b0000;
            error_detected <= 1'b0;
            syndrome <= 3'b000;
        end else begin
            // 第一级：提取数据位和校验位
            data_bit0 = code_in[2];  // 数据位
            data_bit1 = code_in[4];  // 数据位
            data_bit2 = code_in[5];  // 数据位
            data_bit3 = code_in[6];  // 数据位
            
            // 第二级：计算校验位
            parity_bit0 = code_in[0] ^ data_bit0 ^ data_bit1 ^ data_bit3;
            parity_bit1 = code_in[1] ^ data_bit0 ^ data_bit2 ^ data_bit3;
            parity_bit2 = code_in[3] ^ data_bit1 ^ data_bit2 ^ data_bit3;
            
            // 第三级：生成校验码
            syndrome[0] = parity_bit0;
            syndrome[1] = parity_bit1;
            syndrome[2] = parity_bit2;
            
            // 第四级：错误检测
            error_detected = (syndrome != 3'b000);
            
            // 第五级：输出数据
            data_out = {data_bit3, data_bit2, data_bit1, data_bit0};
        end
    end
endmodule