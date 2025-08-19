//SystemVerilog
module binary_to_bcd #(parameter WIDTH=8, DIGITS=3)(
    input wire [WIDTH-1:0] binary_in,
    output reg [4*DIGITS-1:0] bcd_out
);
    integer i, j;
    reg [4*DIGITS-1:0] bcd_reg;
    reg [WIDTH-1:0] bin_reg;
    reg [3:0] digit_val;

    always @* begin
        bcd_reg = { (4*DIGITS){1'b0} };
        bin_reg = binary_in;
        for (i = 0; i < WIDTH; i = i + 1) begin
            // Optimize comparison chain using range check and generate
            for (j = 0; j < DIGITS; j = j + 1) begin
                digit_val = bcd_reg[4*j +: 4];
                // Range check for 5,6,7,8,9: (digit_val >= 5) is equivalent to (digit_val[2] == 1)
                if (digit_val[2] == 1'b1)
                    bcd_reg[4*j +: 4] = digit_val + 4'd3;
            end
            bcd_reg = bcd_reg << 1;
            bcd_reg[0] = bin_reg[WIDTH-1];
            bin_reg = bin_reg << 1;
        end
        bcd_out = bcd_reg;
    end
endmodule