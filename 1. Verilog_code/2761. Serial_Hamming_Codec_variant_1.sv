//SystemVerilog
module Serial_Hamming_Codec(
    input clk,
    input serial_in,
    input serial_in_valid,
    output serial_in_ready,
    output reg serial_out,
    output reg serial_out_valid,
    input serial_out_ready,
    input mode // 0-编码 1-解码
);
    reg [7:0] shift_reg;
    reg [2:0] bit_counter;
    reg processing;
    
    // 添加初始化
    initial begin
        shift_reg = 8'h0;
        bit_counter = 3'h0;
        serial_out = 1'b0;
        serial_out_valid = 1'b0;
        processing = 1'b0;
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

    // 实现接收端ready信号
    assign serial_in_ready = !processing || (bit_counter == 7 && serial_out_ready);

    always @(posedge clk) begin
        if (!processing) begin
            if (serial_in_valid && serial_in_ready) begin
                processing <= 1'b1;
                shift_reg <= {shift_reg[6:0], serial_in};
                bit_counter <= 3'd1;
                serial_out_valid <= 1'b0;
            end
        end else begin
            if (bit_counter < 7) begin
                if (serial_in_valid && serial_in_ready) begin
                    shift_reg <= {shift_reg[6:0], serial_in};
                    bit_counter <= bit_counter + 1;
                end
            end else begin
                // 处理完整字节
                if (!serial_out_valid || (serial_out_valid && serial_out_ready)) begin
                    if (!mode) // 编码模式
                        serial_out <= HammingEncode(shift_reg);
                    else       // 解码模式
                        serial_out <= HammingDecode(shift_reg);
                    
                    serial_out_valid <= 1'b1;
                    processing <= 1'b0;
                    bit_counter <= 3'd0;
                end
            end
        end
        
        // 当接收方接收数据后，清除valid信号
        if (serial_out_valid && serial_out_ready) begin
            serial_out_valid <= 1'b0;
        end
    end
endmodule