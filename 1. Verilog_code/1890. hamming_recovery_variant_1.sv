//SystemVerilog
module hamming_recovery (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [11:0] encoded,
    output wire [7:0] decoded,
    output wire error_detected,
    output wire error_corrected,
    output wire valid_out
);
    // Pipeline stage 1 registers - syndrome calculation
    reg [11:0] encoded_stage1;
    reg [3:0] syndrome_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers - error correction
    reg [11:0] corrected_stage2;
    reg error_detected_stage2;
    reg error_corrected_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers - data extraction
    reg [7:0] decoded_stage3;
    reg error_detected_stage3;
    reg error_corrected_stage3;
    reg valid_stage3;
    
    // Stage 1: Calculate syndrome
    always @(posedge clk) begin
        if (rst) begin
            encoded_stage1 <= 12'b0;
            syndrome_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (valid_in) begin
                encoded_stage1 <= encoded;
                
                syndrome_stage1[0] <= ^{encoded[0], encoded[2], encoded[4], encoded[6], encoded[8], encoded[10]};
                syndrome_stage1[1] <= ^{encoded[1], encoded[2], encoded[5], encoded[6], encoded[9], encoded[10]};
                syndrome_stage1[2] <= ^{encoded[3], encoded[4], encoded[5], encoded[6], encoded[11]};
                syndrome_stage1[3] <= ^{encoded[7], encoded[8], encoded[9], encoded[10], encoded[11]};
                
                valid_stage1 <= valid_in;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Parallel prefix subtractor implementation for Stage 2
    wire [3:0] syndrome;
    wire [3:0] one_constant;
    wire [3:0] subtractor_result;
    wire [3:0] generate_bits;
    wire [3:0] propagate_bits;
    wire [3:0] carry_bits;
    
    assign syndrome = syndrome_stage1;
    assign one_constant = 4'b0001; // Constant 1 for subtraction
    
    // Generate and propagate signals for parallel prefix subtraction
    assign generate_bits = syndrome & (~one_constant);
    assign propagate_bits = syndrome | one_constant;
    
    // Parallel prefix carry chain calculation
    // Level 1
    wire [3:0] g_level1, p_level1;
    assign g_level1[0] = generate_bits[0];
    assign p_level1[0] = propagate_bits[0];
    
    assign g_level1[1] = generate_bits[1] | (propagate_bits[1] & generate_bits[0]);
    assign p_level1[1] = propagate_bits[1] & propagate_bits[0];
    
    assign g_level1[2] = generate_bits[2];
    assign p_level1[2] = propagate_bits[2];
    
    assign g_level1[3] = generate_bits[3];
    assign p_level1[3] = propagate_bits[3];
    
    // Level 2
    wire [3:0] g_level2, p_level2;
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    
    assign g_level2[2] = g_level1[2] | (p_level1[2] & g_level1[1]);
    assign p_level2[2] = p_level1[2] & p_level1[1];
    
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[2]);
    assign p_level2[3] = p_level1[3] & p_level1[2];
    
    // Calculate final carry bits
    assign carry_bits[0] = 1'b1; // Initial borrow for subtraction
    assign carry_bits[1] = g_level2[0] | (p_level2[0] & carry_bits[0]);
    assign carry_bits[2] = g_level2[1] | (p_level2[1] & carry_bits[1]);
    assign carry_bits[3] = g_level2[2] | (p_level2[2] & carry_bits[2]);
    
    // Calculate result of syndrome - 1
    assign subtractor_result = syndrome ^ one_constant ^ carry_bits;
    
    // Stage 2: Process syndrome and perform error correction using the parallel prefix subtractor
    always @(posedge clk) begin
        if (rst) begin
            corrected_stage2 <= 12'b0;
            error_detected_stage2 <= 1'b0;
            error_corrected_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                error_detected_stage2 <= (syndrome_stage1 != 4'b0000);
                
                if (syndrome_stage1 != 4'b0000) begin
                    // Correct bit if error position is valid
                    // Using the parallel prefix subtractor result
                    if (syndrome_stage1 <= 12) begin
                        corrected_stage2 <= encoded_stage1;
                        corrected_stage2[subtractor_result] <= ~encoded_stage1[subtractor_result];
                        error_corrected_stage2 <= 1'b1;
                    end else begin
                        corrected_stage2 <= encoded_stage1;
                        error_corrected_stage2 <= 1'b0;
                    end
                end else begin
                    corrected_stage2 <= encoded_stage1;
                    error_corrected_stage2 <= 1'b0;
                end
                
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Extract data bits
    always @(posedge clk) begin
        if (rst) begin
            decoded_stage3 <= 8'b0;
            error_detected_stage3 <= 1'b0;
            error_corrected_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                decoded_stage3 <= {corrected_stage2[11], corrected_stage2[10], corrected_stage2[9], corrected_stage2[8], 
                                  corrected_stage2[6], corrected_stage2[5], corrected_stage2[4], corrected_stage2[2]};
                error_detected_stage3 <= error_detected_stage2;
                error_corrected_stage3 <= error_corrected_stage2;
                valid_stage3 <= valid_stage2;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Connect outputs to final pipeline stage
    assign decoded = decoded_stage3;
    assign error_detected = error_detected_stage3;
    assign error_corrected = error_corrected_stage3;
    assign valid_out = valid_stage3;
    
endmodule