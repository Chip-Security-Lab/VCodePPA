//SystemVerilog
module ascii_dec_to_bin(
    input  [7:0] ascii_char,
    output reg [3:0] binary_out,
    output reg       valid
);
    wire in_range;
    assign in_range = ~|({ascii_char[7:4]} ^ 4'h3) & (ascii_char[3:0] <= 4'h9);

    always @(*) begin
        if (in_range) begin
            binary_out = ascii_char[3:0];
            valid      = 1'b1;
        end else begin
            binary_out = 4'b0000;
            valid      = 1'b0;
        end
    end
endmodule