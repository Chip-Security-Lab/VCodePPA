//SystemVerilog
module float2fixed #(parameter INT=4, FRAC=4) (
    input wire clk,
    input wire valid_in,
    input wire [31:0] float_in,
    output reg [INT+FRAC-1:0] fixed_out
);

    reg [INT+FRAC-1:0] float_lower_bits_reg;

    always @(posedge clk) begin
        if (valid_in)
            float_lower_bits_reg <= float_in[INT+FRAC-1:0];
    end

    always @(posedge clk) begin
        if (valid_in)
            fixed_out <= float_lower_bits_reg;
    end

endmodule