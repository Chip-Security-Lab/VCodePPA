module fraction_to_integer #(parameter INT_WIDTH=8, FRAC_WIDTH=8)(
    input wire [INT_WIDTH+FRAC_WIDTH-1:0] frac_in,
    output reg [INT_WIDTH-1:0] int_out
);
    wire round_bit = frac_in[FRAC_WIDTH-1];
    
    always @* begin
        int_out = (frac_in >> FRAC_WIDTH) + round_bit;
    end
endmodule