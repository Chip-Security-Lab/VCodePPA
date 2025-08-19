module Interrupt_Hamming_Decoder(
    input clk,
    input [7:0] code_in,
    output reg [3:0] data_out,
    output reg uncorrectable_irq
);
    reg [1:0] error_state;
    
    // 实现解码状态函数
    function [5:0] DecodeWithStatus;
        input [7:0] code;
        reg [3:0] data;
        reg [1:0] state;
        begin
            // 简化解码逻辑
            state = 2'b00; // 默认无错误
            
            // 计算校验位
            if (^code != 0) begin
                if (code[7] ^ code[6] ^ code[5] ^ code[4] != code[0])
                    state = 2'b01; // 1位错误
                else if (code[7] ^ code[6] ^ code[3] ^ code[2] != code[1])
                    state = 2'b10; // 1位错误
                else
                    state = 2'b11; // 不可纠正错误
            end
            
            // 提取数据
            data = code[7:4];
            
            DecodeWithStatus = {data, state};
        end
    endfunction

    always @(posedge clk) begin
        {data_out, error_state} <= DecodeWithStatus(code_in);
        uncorrectable_irq <= (error_state == 2'b11);
    end
endmodule