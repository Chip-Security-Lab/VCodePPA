module ascii_dec_to_bin(
    input [7:0] ascii_char,
    output reg [3:0] binary_out,
    output reg valid
);
    always @(*) begin
        valid = 1'b1;
        if (ascii_char >= 8'h30 && ascii_char <= 8'h39) // ASCII '0'-'9'
            binary_out = ascii_char - 8'h30;
        else begin
            binary_out = 4'b0;
            valid = 1'b0;
        end
    end
endmodule