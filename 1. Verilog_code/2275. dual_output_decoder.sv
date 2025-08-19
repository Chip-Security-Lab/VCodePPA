module dual_output_decoder(
    input [2:0] binary_in,
    output reg [7:0] onehot_out,
    output reg [2:0] gray_out
);
    always @(*) begin
        onehot_out = (8'b1 << binary_in);
        
        // Convert to Gray code
        gray_out[2] = binary_in[2];
        gray_out[1] = binary_in[2] ^ binary_in[1];
        gray_out[0] = binary_in[1] ^ binary_in[0];
    end
endmodule