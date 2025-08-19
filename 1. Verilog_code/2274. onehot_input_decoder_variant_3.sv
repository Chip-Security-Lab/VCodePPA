//SystemVerilog
module onehot_input_decoder(
    input [7:0] onehot_in,
    output reg [2:0] binary_out,
    output reg valid
);
    // More efficient implementation using bitwise operations
    // instead of large case statement
    always @(*) begin
        binary_out[0] = onehot_in[1] | onehot_in[3] | onehot_in[5] | onehot_in[7];
        binary_out[1] = onehot_in[2] | onehot_in[3] | onehot_in[6] | onehot_in[7];
        binary_out[2] = onehot_in[4] | onehot_in[5] | onehot_in[6] | onehot_in[7];
        
        // Check if input is valid one-hot encoding (exactly one bit set)
        valid = (onehot_in != 8'b0) && ((onehot_in & (onehot_in - 1)) == 8'b0);
    end
endmodule