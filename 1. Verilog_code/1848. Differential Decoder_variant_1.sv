//SystemVerilog
module differential_decoder (
    input  wire       clk,
    input  wire       reset_b,
    input  wire       diff_in,
    input  wire       input_valid,    // 新增：输入数据有效信号
    output wire       input_ready,    // 新增：输入就绪信号
    output reg        decoded_out,
    output wire       parity_error,
    output reg        output_valid,   // 新增：输出数据有效信号
    input  wire       output_ready    // 新增：下游模块就绪信号
);
    reg prev_diff_in;
    reg parity_bit;
    reg processing;
    reg [2:0] bit_counter;
    reg expected_parity;
    
    // 握手逻辑处理
    assign input_ready = !processing || (output_valid && output_ready);
    
    // 合并所有具有相同触发条件的always块
    always @(posedge clk or negedge reset_b) begin
        if (!reset_b) begin
            // 重置所有寄存器
            processing <= 1'b0;
            output_valid <= 1'b0;
            prev_diff_in <= 1'b0;
            decoded_out <= 1'b0;
            parity_bit <= 1'b0;
            bit_counter <= 3'b000;
            expected_parity <= 1'b0;
        end else begin
            // 处理握手逻辑和状态控制
            if (input_valid && input_ready) begin
                // 处理新输入
                processing <= 1'b1;
                output_valid <= 1'b0;
                
                // 差分解码
                prev_diff_in <= diff_in;
                decoded_out <= diff_in ^ prev_diff_in;
                parity_bit <= parity_bit ^ (diff_in ^ prev_diff_in);
                
                // 位计数和奇偶校验
                bit_counter <= bit_counter + 1'b1;
                if (bit_counter == 3'b111)
                    expected_parity <= ~expected_parity;
            end
            
            // 处理过程中的状态更新
            if (processing) begin
                output_valid <= 1'b1;
            end
            
            // 完成处理后的状态重置
            if (output_valid && output_ready) begin
                processing <= 1'b0;
                output_valid <= 1'b0;
            end
        end
    end
    
    // 奇偶校验错误检测
    assign parity_error = (bit_counter == 3'b000 && output_valid) ? (parity_bit != expected_parity) : 1'b0;
endmodule