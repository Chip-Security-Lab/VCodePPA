//SystemVerilog
module hamming_encoder_self_test(
    input clk, rst, test_mode,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg test_pass
);
    reg [3:0] test_vector;
    reg [6:0] expected_code;
    
    // Manchester Carry Chain signals
    wire [6:0] encoder_input;
    wire [6:0] encoder_output;
    wire [6:0] p; // Propagate signals
    wire [6:0] g; // Generate signals
    wire [7:0] c; // Carry signals (including initial carry)
    
    // Select input source based on mode
    assign encoder_input = test_mode ? {test_vector[3:0], 3'b0} : {data_in[3:0], 3'b0};
    
    // Generate propagate and generate signals
    assign p[0] = encoder_input[0] ^ encoder_input[1] ^ encoder_input[3];
    assign p[1] = encoder_input[0] ^ encoder_input[2] ^ encoder_input[3];
    assign p[2] = encoder_input[0];
    assign p[3] = encoder_input[1] ^ encoder_input[2] ^ encoder_input[3];
    assign p[4] = encoder_input[1];
    assign p[5] = encoder_input[2];
    assign p[6] = encoder_input[3];
    
    assign g = 7'b0; // No generate signals in this implementation
    
    // Manchester Carry Chain implementation
    assign c[0] = 1'b0; // Initial carry is 0
    
    // Fast carry propagation using Manchester Carry Chain
    genvar i;
    generate
        for (i = 0; i < 7; i = i + 1) begin : carry_chain
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
    
    // Calculate the output using the carry chain
    assign encoder_output = p ^ c[6:0];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            test_pass <= 1'b0;
            test_vector <= 4'b0;
        end else if (test_mode) begin
            // Test mode increments through all possible 4-bit values
            test_vector <= test_vector + 1;
            
            // Update encoded output with Manchester Carry Chain result
            encoded <= encoder_output;
            
            // Set expected code based on test vector for comparison
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
            // Normal operation - update encoded output with Manchester Carry Chain result
            encoded <= encoder_output;
        end
    end
endmodule