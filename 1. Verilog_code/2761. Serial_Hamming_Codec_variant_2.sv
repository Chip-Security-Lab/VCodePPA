//SystemVerilog
module Serial_Hamming_Codec(
    input clk,
    input serial_in,
    output reg serial_out,
    input mode // 0-编码 1-解码
);
    reg [7:0] shift_reg;
    reg [2:0] bit_counter;
    
    // 添加初始化
    initial begin
        shift_reg = 8'h0;
        bit_counter = 3'h0;
        serial_out = 1'b0;
    end
    
    wire hamming_result;
    // 优化的汉明编码实现
    assign hamming_result = mode ? shift_reg[0] : 
                                  (shift_reg[0] ^ shift_reg[1] ^ shift_reg[3]);

    always @(posedge clk) begin
        if(bit_counter < 7) begin
            shift_reg <= {shift_reg[6:0], serial_in};
            bit_counter <= bit_counter + 1;
        end
        else begin
            // 处理完整字节
            serial_out <= hamming_result;
            bit_counter <= 3'b0;
            shift_reg <= {shift_reg[6:0], serial_in};
        end
    end
endmodule