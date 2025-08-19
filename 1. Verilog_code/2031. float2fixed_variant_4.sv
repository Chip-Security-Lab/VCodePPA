//SystemVerilog
module float2fixed #(parameter INT=4, FRAC=4) (
    input clk,
    input valid_in,
    input [31:0] float_in,
    output reg [INT+FRAC-1:0] fixed_out
);
    localparam TOTAL_BITS = INT + FRAC;
    wire [31:0] masked_input;
    assign masked_input = float_in & {32{(TOTAL_BITS != 0)}} & (32'hFFFFFFFF >> (32 - TOTAL_BITS));

    always @(posedge clk) begin
        if (valid_in) begin
            fixed_out <= masked_input[TOTAL_BITS-1:0];
        end
    end
endmodule