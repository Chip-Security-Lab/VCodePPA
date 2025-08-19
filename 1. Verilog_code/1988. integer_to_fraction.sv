module integer_to_fraction #(parameter INT_WIDTH=8, FRAC_WIDTH=8)(
    input wire [INT_WIDTH-1:0] int_in,
    input wire [INT_WIDTH-1:0] denominator, // 分母
    output reg [INT_WIDTH+FRAC_WIDTH-1:0] frac_out
);
    reg [INT_WIDTH+FRAC_WIDTH-1:0] extended_int;
    
    always @* begin
        extended_int = int_in << FRAC_WIDTH;
        frac_out = extended_int / denominator;
    end
endmodule