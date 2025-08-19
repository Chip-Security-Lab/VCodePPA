//SystemVerilog
module Hamming_Error_Injection(
    input clk,
    input error_en,
    input [3:0] error_position,
    input [7:0] clean_code,
    output reg [7:0] corrupted_code
);
    // Simplified error mask generation with direct bit selection
    always @(posedge clk) begin
        if (error_en)
            corrupted_code <= clean_code ^ (8'b1 << error_position);
        else
            corrupted_code <= clean_code;
    end
endmodule