module binary_decoder(
    input [3:0] addr_in,
    output reg [15:0] select_out
);
    always @(*) begin
        select_out = 16'b0;
        select_out[addr_in] = 1'b1;
    end
endmodule