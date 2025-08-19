module hex2ascii (
    input wire [3:0] hex_in,
    output reg [7:0] ascii_out
);
    always @(*) begin
        if (hex_in <= 4'h9)
            ascii_out = hex_in + 8'h30;  // 0-9 to ASCII '0'-'9'
        else
            ascii_out = hex_in + 8'h37;  // A-F to ASCII 'A'-'F'
    end
endmodule