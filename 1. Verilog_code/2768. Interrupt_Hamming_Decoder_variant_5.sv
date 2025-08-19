//SystemVerilog
module Interrupt_Hamming_Decoder(
    input clk,
    input [7:0] code_in,
    output reg [3:0] data_out,
    output reg uncorrectable_irq
);
    reg [1:0] error_state;
    
    // 声明优化后的检测信号
    wire parity_total;
    wire p0_error;
    wire p1_error;
    
    // 计算校验位，使用XOR树结构减少门延迟
    assign parity_total = ^code_in;
    assign p0_error = code_in[7] ^ code_in[6] ^ code_in[5] ^ code_in[4] ^ code_in[0];
    assign p1_error = code_in[7] ^ code_in[6] ^ code_in[3] ^ code_in[2] ^ code_in[1];
    
    // 组合逻辑优化错误状态检测
    always @(posedge clk) begin
        // 直接提取数据位
        data_out <= code_in[7:4];
        
        // 优化状态检测逻辑
        if (!parity_total) begin
            // 无错误
            error_state <= 2'b00;
            uncorrectable_irq <= 1'b0;
        end else if (p0_error) begin
            // 1位错误，校验位0错误
            error_state <= 2'b01;
            uncorrectable_irq <= 1'b0;
        end else if (p1_error) begin
            // 1位错误，校验位1错误
            error_state <= 2'b10;
            uncorrectable_irq <= 1'b0;
        end else begin
            // 不可纠正错误
            error_state <= 2'b11;
            uncorrectable_irq <= 1'b1;
        end
    end
endmodule