//SystemVerilog
module Serial_Hamming_Codec(
    input clk,
    input serial_in,
    output reg serial_out,
    input mode // 0-编码 1-解码
);
    reg [7:0] shift_reg;
    reg [2:0] bit_counter;
    
    // 添加缓冲寄存器以降低扇出负载
    reg [2:0] bit_counter_buf1, bit_counter_buf2;
    reg [7:0] shift_reg_buf1, shift_reg_buf2;
    
    // 添加初始化
    initial begin
        shift_reg = 8'h0;
        bit_counter = 3'h0;
        serial_out = 1'b0;
        bit_counter_buf1 = 3'h0;
        bit_counter_buf2 = 3'h0;
        shift_reg_buf1 = 8'h0;
        shift_reg_buf2 = 8'h0;
    end
    
    // 实现汉明编码函数
    function HammingEncode;
        input [7:0] data;
        begin
            // 简化的汉明编码，只处理单比特
            HammingEncode = data[0] ^ data[1] ^ data[3];
        end
    endfunction
    
    // 实现汉明解码函数
    function HammingDecode;
        input [7:0] code;
        begin
            // 简化的汉明解码，只处理单比特
            HammingDecode = code[0];
        end
    endfunction

    // 缓冲寄存器更新逻辑
    always @(posedge clk) begin
        // 双级缓冲，分散负载
        bit_counter_buf1 <= bit_counter;
        bit_counter_buf2 <= bit_counter_buf1;
        
        shift_reg_buf1 <= shift_reg;
        shift_reg_buf2 <= shift_reg_buf1;
    end

    always @(posedge clk) begin
        if(bit_counter_buf1 < 7) begin
            shift_reg <= {shift_reg[6:0], serial_in};
            bit_counter <= bit_counter + 1;
            // 确保serial_out有默认值
            serial_out <= serial_out;
        end
        else begin
            // 使用缓冲的数据处理完整字节，减轻关键路径负载
            if(!mode) // 编码模式
                serial_out <= HammingEncode(shift_reg_buf2);
            else       // 解码模式
                serial_out <= HammingDecode(shift_reg_buf2);
            bit_counter <= 0;
        end
    end
endmodule