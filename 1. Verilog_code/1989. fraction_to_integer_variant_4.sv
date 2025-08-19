//SystemVerilog
module fraction_to_integer #(parameter INT_WIDTH=8, FRAC_WIDTH=8)(
    input wire [INT_WIDTH+FRAC_WIDTH-1:0] frac_in,
    output reg [INT_WIDTH-1:0] int_out
);
    wire round_bit;
    wire [INT_WIDTH-1:0] integer_part;
    wire [INT_WIDTH-1:0] round_addend;
    wire [INT_WIDTH-1:0] two_complement_one;
    wire [INT_WIDTH-1:0] sum_result;

    assign round_bit = frac_in[FRAC_WIDTH-1];
    assign integer_part = frac_in[INT_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
    assign two_complement_one = ~8'd0 + 8'd1; // 8'hFF + 1 = 0, so ~0 + 1 = 0x00 + 1 = 1
    assign round_addend = round_bit ? two_complement_one : {INT_WIDTH{1'b0}};
    assign sum_result = integer_part + round_addend;

    always @* begin
        int_out = sum_result;
    end
endmodule