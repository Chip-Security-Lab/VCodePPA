//SystemVerilog
module hex2ascii (
    input wire [3:0] hex_in,
    output reg [7:0] ascii_out
);
    always @(*) begin
        if (hex_in[3] == 1'b0 && hex_in[2:0] <= 3'b1001) begin
            ascii_out = {4'b0011, hex_in}; // 8'h30 + hex_in
        end else begin
            ascii_out = {4'b0100, hex_in} - 8'h09; // 8'h41 + (hex_in - 4'hA)
        end
    end
endmodule