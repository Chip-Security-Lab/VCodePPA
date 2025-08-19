//SystemVerilog
module Hamming_Error_Injection(
    input clk,
    input error_en,
    input [3:0] error_position,
    input [7:0] clean_code,
    output reg [7:0] corrupted_code
);
    // 内部信号定义
    reg [7:0] error_mask;
    reg [7:0] code_with_error;
    
    // 生成错误掩码
    always @(posedge clk) begin
        if (error_en)
            error_mask <= (1'b1 << error_position);
        else
            error_mask <= 8'b0;
    end
    
    // 应用错误掩码到数据
    always @(posedge clk) begin
        code_with_error <= clean_code ^ error_mask;
    end
    
    // 输出选择逻辑
    always @(posedge clk) begin
        if (error_en)
            corrupted_code <= code_with_error;
        else
            corrupted_code <= clean_code;
    end
endmodule