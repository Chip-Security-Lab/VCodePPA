module float2fixed #(parameter INT=4, FRAC=4) (
    input clk, valid_in,
    input [31:0] float_in,
    output reg [INT+FRAC-1:0] fixed_out
);
    wire [INT+FRAC-1:0] temp = float_in[INT+FRAC-1:0];
    always @(posedge clk) begin
        if (valid_in) fixed_out <= temp;
    end
endmodule