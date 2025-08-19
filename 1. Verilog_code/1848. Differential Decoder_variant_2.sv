//SystemVerilog
module differential_decoder (
    input  wire       clk,
    input  wire       reset_b,
    input  wire       diff_in,
    output reg        decoded_out,
    output reg        parity_error
);
    reg prev_diff_in;
    reg parity_bit;
    reg [2:0] bit_counter;
    reg expected_parity;
    wire next_decoded_out;
    
    // 简化为线网声明，减少逻辑门数量
    assign next_decoded_out = diff_in ^ prev_diff_in;
    
    // 主时序逻辑
    always @(posedge clk or negedge reset_b) begin
        if (!reset_b) begin
            prev_diff_in <= 1'b0;
            decoded_out <= 1'b0;
            parity_bit <= 1'b0;
            bit_counter <= 3'b000;
            expected_parity <= 1'b0;
            parity_error <= 1'b0;
        end else begin
            prev_diff_in <= diff_in;
            decoded_out <= next_decoded_out;
            
            // 增量计数器
            bit_counter <= bit_counter + 3'b001;
            
            // 优化奇偶校验位更新逻辑，减少寄存器和逻辑开销
            parity_bit <= (bit_counter == 3'b000) ? 1'b0 : (parity_bit ^ next_decoded_out);
            
            // 简化奇偶校验逻辑
            if (bit_counter == 3'b111) begin
                expected_parity <= ~expected_parity;
            end
            
            // 优化错误检测条件判断，减少逻辑深度
            parity_error <= (bit_counter == 3'b000) ? (parity_bit ^ expected_parity) : 1'b0;
        end
    end
endmodule