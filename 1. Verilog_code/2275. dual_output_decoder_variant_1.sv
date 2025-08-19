//SystemVerilog
module dual_output_decoder(
    input [2:0] binary_in,
    output reg [7:0] onehot_out,
    output reg [2:0] gray_out
);
    // One-hot encoder in a separate always block
    always @(*) begin
        onehot_out = 8'b0; // Default assignment
        case (binary_in)
            3'b000: onehot_out = 8'b00000001;
            3'b001: onehot_out = 8'b00000010;
            3'b010: onehot_out = 8'b00000100;
            3'b011: onehot_out = 8'b00001000;
            3'b100: onehot_out = 8'b00010000;
            3'b101: onehot_out = 8'b00100000;
            3'b110: onehot_out = 8'b01000000;
            3'b111: onehot_out = 8'b10000000;
        endcase
    end
    
    // Gray code conversion in a separate always block
    always @(*) begin
        gray_out[2] = binary_in[2];
        gray_out[1] = binary_in[2] ^ binary_in[1];
        gray_out[0] = binary_in[1] ^ binary_in[0];
    end
endmodule