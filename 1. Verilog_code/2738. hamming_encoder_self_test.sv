module hamming_encoder_self_test(
    input clk, rst, test_mode,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg test_pass
);
    reg [3:0] test_vector;
    reg [6:0] expected_code;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            test_pass <= 1'b0;
            test_vector <= 4'b0;
        end else if (test_mode) begin
            // Test mode increments through all possible 4-bit values
            test_vector <= test_vector + 1;
            
            // Calculate encoded value for test vector
            encoded[0] <= test_vector[0] ^ test_vector[1] ^ test_vector[3];
            encoded[1] <= test_vector[0] ^ test_vector[2] ^ test_vector[3];
            encoded[2] <= test_vector[0];
            encoded[3] <= test_vector[1] ^ test_vector[2] ^ test_vector[3];
            encoded[4] <= test_vector[1];
            encoded[5] <= test_vector[2];
            encoded[6] <= test_vector[3];
            
            // Set expected code based on test vector
            expected_code[0] = test_vector[0] ^ test_vector[1] ^ test_vector[3];
            expected_code[1] = test_vector[0] ^ test_vector[2] ^ test_vector[3];
            expected_code[2] = test_vector[0];
            expected_code[3] = test_vector[1] ^ test_vector[2] ^ test_vector[3];
            expected_code[4] = test_vector[1];
            expected_code[5] = test_vector[2];
            expected_code[6] = test_vector[3];
            
            // Check if encoded matches expected
            test_pass <= (encoded == expected_code);
        end else begin
            // Normal operation
            encoded[0] <= data_in[0] ^ data_in[1] ^ data_in[3];
            encoded[1] <= data_in[0] ^ data_in[2] ^ data_in[3];
            encoded[2] <= data_in[0];
            encoded[3] <= data_in[1] ^ data_in[2] ^ data_in[3];
            encoded[4] <= data_in[1];
            encoded[5] <= data_in[2];
            encoded[6] <= data_in[3];
        end
    end
endmodule