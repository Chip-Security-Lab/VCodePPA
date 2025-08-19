module Hamming_Error_Injection(
    input clk,
    input error_en,
    input [3:0] error_position,
    input [7:0] clean_code,
    output reg [7:0] corrupted_code
);
always @(posedge clk) begin
    corrupted_code <= error_en ? 
        clean_code ^ (1'b1 << error_position) : 
        clean_code;
end
endmodule