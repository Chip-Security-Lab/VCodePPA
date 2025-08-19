//SystemVerilog
module hamming_encoder_self_test(
    input clk, rst, test_mode,
    input [3:0] data_in,
    output reg [6:0] encoded,
    output reg test_pass
);
    reg [3:0] test_vector_stage1;
    reg [3:0] test_vector_stage2;
    reg [6:0] expected_code_stage1;
    reg [6:0] expected_code_stage2;
    reg [6:0] encoded_stage1;
    reg [6:0] encoded_stage2;
    reg test_pass_stage1;
    reg test_pass_stage2;
    
    // Stage 1: Input and initial calculations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            test_vector_stage1 <= 4'b0;
            encoded_stage1 <= 7'b0;
            test_pass_stage1 <= 1'b0;
        end else if (test_mode) begin
            test_vector_stage1 <= test_vector_stage2 + 1;
            
            // Calculate parity bits
            encoded_stage1[0] <= test_vector_stage2[0] ^ test_vector_stage2[1];
            encoded_stage1[1] <= test_vector_stage2[0] ^ test_vector_stage2[2];
            encoded_stage1[3] <= test_vector_stage2[1] ^ test_vector_stage2[2];
            
            // Store data bits
            encoded_stage1[2] <= test_vector_stage2[0];
            encoded_stage1[4] <= test_vector_stage2[1];
            encoded_stage1[5] <= test_vector_stage2[2];
            encoded_stage1[6] <= test_vector_stage2[3];
        end else begin
            // Normal operation stage 1
            encoded_stage1[0] <= data_in[0] ^ data_in[1];
            encoded_stage1[1] <= data_in[0] ^ data_in[2];
            encoded_stage1[3] <= data_in[1] ^ data_in[2];
            encoded_stage1[2] <= data_in[0];
            encoded_stage1[4] <= data_in[1];
            encoded_stage1[5] <= data_in[2];
            encoded_stage1[6] <= data_in[3];
        end
    end
    
    // Stage 2: Final calculations and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            test_vector_stage2 <= 4'b0;
            encoded_stage2 <= 7'b0;
            test_pass_stage2 <= 1'b0;
            expected_code_stage2 <= 7'b0;
        end else begin
            test_vector_stage2 <= test_vector_stage1;
            
            // Complete parity calculations
            encoded_stage2[0] <= encoded_stage1[0] ^ test_vector_stage1[3];
            encoded_stage2[1] <= encoded_stage1[1] ^ test_vector_stage1[3];
            encoded_stage2[3] <= encoded_stage1[3] ^ test_vector_stage1[3];
            
            // Pass through data bits
            encoded_stage2[2] <= encoded_stage1[2];
            encoded_stage2[4] <= encoded_stage1[4];
            encoded_stage2[5] <= encoded_stage1[5];
            encoded_stage2[6] <= encoded_stage1[6];
            
            // Calculate expected code
            expected_code_stage2[0] = test_vector_stage1[0] ^ test_vector_stage1[1] ^ test_vector_stage1[3];
            expected_code_stage2[1] = test_vector_stage1[0] ^ test_vector_stage1[2] ^ test_vector_stage1[3];
            expected_code_stage2[2] = test_vector_stage1[0];
            expected_code_stage2[3] = test_vector_stage1[1] ^ test_vector_stage1[2] ^ test_vector_stage1[3];
            expected_code_stage2[4] = test_vector_stage1[1];
            expected_code_stage2[5] = test_vector_stage1[2];
            expected_code_stage2[6] = test_vector_stage1[3];
            
            // Check if encoded matches expected
            test_pass_stage2 <= (encoded_stage2 == expected_code_stage2);
        end
    end
    
    // Output assignment
    always @(posedge clk) begin
        encoded <= encoded_stage2;
        test_pass <= test_pass_stage2;
    end
endmodule