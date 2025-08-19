module q_format_converter_15_to_31(
    input wire [15:0] q15_in,
    output reg [31:0] q31_out
);
    wire sign = q15_in[15];
    wire [14:0] magnitude = q15_in[14:0];
    
    always @* begin
        q31_out = {sign, magnitude, 16'b0};
    end
endmodule