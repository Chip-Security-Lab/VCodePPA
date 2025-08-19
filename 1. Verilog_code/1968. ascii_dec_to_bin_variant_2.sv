//SystemVerilog
module ascii_dec_to_bin(
    input  wire [7:0] ascii_char,
    output reg  [3:0] binary_out,
    output reg        valid
);
    wire in_range;
    assign in_range = (ascii_char[7:4] == 4'h3) && (ascii_char[3:0] <= 4'h9);

    always @(*) begin
        binary_out = in_range ? ascii_char[3:0] : 4'b0;
        valid      = in_range ? 1'b1 : 1'b0;
    end
endmodule