//SystemVerilog
module hamming_encoder_self_test(
    input clk, rst, test_mode,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg test_pass
);
    reg [3:0] test_vector;
    reg [6:0] expected_code;
    wire [2:0] parity_bits;
    reg [2:0] test_parity_bits;
    reg [3:0] data_to_encode;
    
    // Pre-compute parity bits for current input data to balance paths
    assign parity_bits[0] = data_in[0] ^ data_in[1] ^ data_in[3];
    assign parity_bits[1] = data_in[0] ^ data_in[2] ^ data_in[3]; 
    assign parity_bits[2] = data_in[1] ^ data_in[2] ^ data_in[3];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            test_pass <= 1'b0;
            test_vector <= 4'b0;
            test_parity_bits <= 3'b0;
        end else begin
            // Determine which data to encode based on mode
            data_to_encode = test_mode ? test_vector : data_in;
            
            if (test_mode) begin
                // Test mode increments through all possible 4-bit values
                test_vector <= test_vector + 1;
                
                // Pre-compute test vector parity bits for next cycle
                test_parity_bits[0] <= test_vector[0] ^ test_vector[1] ^ test_vector[3];
                test_parity_bits[1] <= test_vector[0] ^ test_vector[2] ^ test_vector[3];
                test_parity_bits[2] <= test_vector[1] ^ test_vector[2] ^ test_vector[3];
                
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
            end
            
            // Unified encoding logic for both modes to reduce redundancy
            encoded[0] <= test_mode ? test_parity_bits[0] : parity_bits[0];
            encoded[1] <= test_mode ? test_parity_bits[1] : parity_bits[1];
            encoded[2] <= data_to_encode[0];
            encoded[3] <= test_mode ? test_parity_bits[2] : parity_bits[2];
            encoded[4] <= data_to_encode[1];
            encoded[5] <= data_to_encode[2];
            encoded[6] <= data_to_encode[3];
        end
    end
endmodule