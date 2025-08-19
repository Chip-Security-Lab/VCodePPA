//SystemVerilog
module lfsr_waveform(
    input i_clk,
    input i_rst,
    input i_valid,           // 替代 i_req，表示输入数据有效
    output o_ready,          // 替代 o_ack，表示准备接收输入
    output [7:0] o_random,   // 随机数输出
    output o_valid,          // 替代 o_req，表示输出数据有效
    input i_ready            // 替代 i_ack，表示下游准备接收数据
);
    reg [15:0] lfsr;
    reg output_valid;
    wire feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];
    wire input_handshake = i_valid && o_ready;
    wire output_handshake = o_valid && i_ready;
    
    // 随时准备接收新指令，除非输出数据有效但未被接收
    assign o_ready = !output_valid || i_ready;
    
    // 输出有效信号
    assign o_valid = output_valid;
    
    always @(posedge i_clk) begin
        if (i_rst) begin
            lfsr <= 16'hACE1;
            output_valid <= 1'b0;
        end else begin
            // 当输入握手成功时更新LFSR并设置输出有效
            if (input_handshake) begin
                lfsr <= {lfsr[14:0], feedback};
                output_valid <= 1'b1;
            end
            
            // 当输出握手成功时清除输出有效标志
            if (output_handshake) begin
                output_valid <= 1'b0;
            end
        end
    end
    
    assign o_random = lfsr[7:0];
endmodule