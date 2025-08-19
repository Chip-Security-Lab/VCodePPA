module active_low_decoder(
    input [2:0] address,
    output reg [7:0] decode_n
);
    always @(*) begin
        decode_n = 8'hFF;  // Default all outputs to inactive (high)
        decode_n[address] = 1'b0;  // Only selected output is active (low)
    end
endmodule