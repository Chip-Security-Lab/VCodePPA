//SystemVerilog
module ft_display_codec (
    input clk, rst_n,
    input [23:0] rgb_in,
    input data_valid,
    input ecc_enable,
    output reg [19:0] protected_out,  // 16-bit data + 4-bit Hamming code
    output reg error_detected,
    output reg [15:0] rgb565_out
);
    // Hamming code generation function (simplified)
    function [3:0] gen_hamming;
        input [15:0] data;
        begin
            gen_hamming[0] = ^{data[0], data[1], data[3], data[4], data[6], data[8], data[10], data[11], data[13], data[15]};
            gen_hamming[1] = ^{data[0], data[2], data[3], data[5], data[6], data[9], data[10], data[12], data[13]};
            gen_hamming[2] = ^{data[1], data[2], data[3], data[7], data[8], data[9], data[10], data[14], data[15]};
            gen_hamming[3] = ^{data[4], data[5], data[6], data[7], data[8], data[9], data[10]};
        end
    endfunction
    
    // Error correction function (simplified)
    function [15:0] correct_error;
        input [15:0] data;
        input [3:0] syndrome;
        reg [15:0] result;
        begin
            result = data;
            case (syndrome)
                4'h1: result[0] = ~data[0];
                4'h2: result[1] = ~data[1];
                4'h3: result[2] = ~data[2];
                4'h4: result[3] = ~data[3];
                4'h5: result[4] = ~data[4];
                4'h6: result[5] = ~data[5];
                4'h7: result[6] = ~data[6];
                4'h8: result[7] = ~data[7];
                4'h9: result[8] = ~data[8];
                4'hA: result[9] = ~data[9];
                4'hB: result[10] = ~data[10];
                4'hC: result[11] = ~data[11];
                4'hD: result[12] = ~data[12];
                4'hE: result[13] = ~data[13];
                4'hF: result[14] = ~data[14];
                // Default case handles no error or double error
            endcase
            correct_error = result;
        end
    endfunction
    
    // Pipeline stage signals
    reg [23:0] rgb_in_stage1;
    reg data_valid_stage1, ecc_enable_stage1;
    
    // RGB conversion pipeline stages
    reg [15:0] rgb565_stage1;
    reg [15:0] rgb565_stage2;
    reg [15:0] rgb565_stage3;
    
    // ECC calculation pipeline stages
    reg [3:0] ecc_bits_stage1;
    reg [3:0] ecc_bits_stage2;
    
    // Syndrome calculation pipeline stages
    reg [3:0] syndrome_stage1;
    reg [3:0] syndrome_stage2;
    
    // Control signal pipeline stages
    reg ecc_enable_stage2;
    reg ecc_enable_stage3;
    reg data_valid_stage2;
    reg data_valid_stage3;
    
    // Hamming code partial calculation signals
    reg [7:0] hamming_partial1_stage1;
    reg [7:0] hamming_partial2_stage1;

    //--------------------------------------------------
    // Stage 1: Input registration and RGB conversion
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_in_stage1 <= 24'h0;
            data_valid_stage1 <= 1'b0;
            ecc_enable_stage1 <= 1'b0;
        end else begin
            rgb_in_stage1 <= rgb_in;
            data_valid_stage1 <= data_valid;
            ecc_enable_stage1 <= ecc_enable;
        end
    end
    
    //--------------------------------------------------
    // Stage 1: RGB888 to RGB565 conversion
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_stage1 <= 16'h0;
        end else if (data_valid) begin
            // RGB888 to RGB565 conversion
            rgb565_stage1 <= {rgb_in[23:19], rgb_in[15:10], rgb_in[7:3]};
        end
    end
    
    //--------------------------------------------------
    // Stage 2: Control signals propagation
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_stage2 <= 16'h0;
            data_valid_stage2 <= 1'b0;
            ecc_enable_stage2 <= 1'b0;
        end else begin
            rgb565_stage2 <= rgb565_stage1;
            data_valid_stage2 <= data_valid_stage1;
            ecc_enable_stage2 <= ecc_enable_stage1;
        end
    end
    
    //--------------------------------------------------
    // Stage 2: First set of Hamming code partial calculations
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hamming_partial1_stage1 <= 8'h0;
        end else if (data_valid_stage1) begin
            // First set of partial calculations for Hamming code
            hamming_partial1_stage1[0] <= rgb565_stage1[0] ^ rgb565_stage1[1] ^ rgb565_stage1[3] ^ rgb565_stage1[4];
            hamming_partial1_stage1[1] <= rgb565_stage1[6] ^ rgb565_stage1[8] ^ rgb565_stage1[10] ^ rgb565_stage1[11];
            hamming_partial1_stage1[2] <= rgb565_stage1[13] ^ rgb565_stage1[15];
            hamming_partial1_stage1[3] <= rgb565_stage1[0] ^ rgb565_stage1[2] ^ rgb565_stage1[3] ^ rgb565_stage1[5];
        end
    end
    
    //--------------------------------------------------
    // Stage 2: Second set of Hamming code partial calculations
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hamming_partial2_stage1 <= 8'h0;
        end else if (data_valid_stage1) begin
            // Second set of partial calculations for Hamming code
            hamming_partial2_stage1[0] <= rgb565_stage1[6] ^ rgb565_stage1[9] ^ rgb565_stage1[10] ^ rgb565_stage1[12];
            hamming_partial2_stage1[1] <= rgb565_stage1[13];
            hamming_partial2_stage1[2] <= rgb565_stage1[1] ^ rgb565_stage1[2] ^ rgb565_stage1[3] ^ rgb565_stage1[7];
            hamming_partial2_stage1[3] <= rgb565_stage1[8] ^ rgb565_stage1[9] ^ rgb565_stage1[10] ^ rgb565_stage1[14];
            hamming_partial2_stage1[4] <= rgb565_stage1[15];
            hamming_partial2_stage1[5] <= rgb565_stage1[4] ^ rgb565_stage1[5] ^ rgb565_stage1[6] ^ rgb565_stage1[7];
            hamming_partial2_stage1[6] <= rgb565_stage1[8] ^ rgb565_stage1[9] ^ rgb565_stage1[10];
            hamming_partial2_stage1[7] <= 1'b0; // Unused
        end
    end
    
    //--------------------------------------------------
    // Stage 3: Control signals propagation
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_stage3 <= 16'h0;
            data_valid_stage3 <= 1'b0;
            ecc_enable_stage3 <= 1'b0;
        end else begin
            rgb565_stage3 <= rgb565_stage2;
            data_valid_stage3 <= data_valid_stage2;
            ecc_enable_stage3 <= ecc_enable_stage2;
        end
    end
    
    //--------------------------------------------------
    // Stage 3: Complete Hamming code calculation
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ecc_bits_stage1 <= 4'h0;
        end else if (data_valid_stage2) begin
            // Complete Hamming code calculation by combining partial results
            ecc_bits_stage1[0] <= hamming_partial1_stage1[0] ^ hamming_partial1_stage1[1] ^ hamming_partial1_stage1[2];
            ecc_bits_stage1[1] <= hamming_partial1_stage1[3] ^ hamming_partial2_stage1[0] ^ hamming_partial2_stage1[1];
            ecc_bits_stage1[2] <= hamming_partial2_stage1[2] ^ hamming_partial2_stage1[3] ^ hamming_partial2_stage1[4];
            ecc_bits_stage1[3] <= hamming_partial2_stage1[5] ^ hamming_partial2_stage1[6];
        end
    end
    
    //--------------------------------------------------
    // Stage 4: Protected output generation
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ecc_bits_stage2 <= 4'h0;
            protected_out <= 20'h0;
        end else if (data_valid_stage3) begin
            ecc_bits_stage2 <= ecc_bits_stage1;
            
            if (ecc_enable_stage3) begin
                protected_out <= {rgb565_stage3, ecc_bits_stage1};
            end else begin
                protected_out <= {rgb565_stage3, 4'h0};
            end
        end
    end
    
    //--------------------------------------------------
    // Stage 4: Syndrome calculation
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_stage1 <= 4'h0;
        end else if (data_valid_stage3) begin
            if (ecc_enable_stage3) begin
                // Calculate syndrome based on current data and ECC bits
                syndrome_stage1[0] <= ^{rgb565_stage3[0], rgb565_stage3[1], rgb565_stage3[3], rgb565_stage3[4], 
                                       rgb565_stage3[6], rgb565_stage3[8], rgb565_stage3[10], rgb565_stage3[11], 
                                       rgb565_stage3[13], rgb565_stage3[15]} ^ ecc_bits_stage1[0];
                syndrome_stage1[1] <= ^{rgb565_stage3[0], rgb565_stage3[2], rgb565_stage3[3], rgb565_stage3[5], 
                                       rgb565_stage3[6], rgb565_stage3[9], rgb565_stage3[10], rgb565_stage3[12], 
                                       rgb565_stage3[13]} ^ ecc_bits_stage1[1];
                syndrome_stage1[2] <= ^{rgb565_stage3[1], rgb565_stage3[2], rgb565_stage3[3], rgb565_stage3[7], 
                                       rgb565_stage3[8], rgb565_stage3[9], rgb565_stage3[10], rgb565_stage3[14], 
                                       rgb565_stage3[15]} ^ ecc_bits_stage1[2];
                syndrome_stage1[3] <= ^{rgb565_stage3[4], rgb565_stage3[5], rgb565_stage3[6], rgb565_stage3[7], 
                                       rgb565_stage3[8], rgb565_stage3[9], rgb565_stage3[10]} ^ ecc_bits_stage1[3];
            end else begin
                syndrome_stage1 <= 4'h0;
            end
        end
    end
    
    //--------------------------------------------------
    // Stage 5: Error detection
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_stage2 <= 4'h0;
            error_detected <= 1'b0;
        end else begin
            syndrome_stage2 <= syndrome_stage1;
            // Error detection
            error_detected <= (syndrome_stage1 != 4'h0) && (|syndrome_stage1);
        end
    end
    
    //--------------------------------------------------
    // Stage 5: Error correction
    //--------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_out <= 16'h0000;
        end else if (ecc_enable_stage3 && data_valid_stage3) begin
            if (syndrome_stage1 != 4'h0) begin
                case (syndrome_stage1)
                    4'h1: rgb565_out <= {rgb565_stage3[15:1], ~rgb565_stage3[0]};
                    4'h2: rgb565_out <= {rgb565_stage3[15:2], ~rgb565_stage3[1], rgb565_stage3[0]};
                    4'h3: rgb565_out <= {rgb565_stage3[15:3], ~rgb565_stage3[2], rgb565_stage3[1:0]};
                    4'h4: rgb565_out <= {rgb565_stage3[15:4], ~rgb565_stage3[3], rgb565_stage3[2:0]};
                    4'h5: rgb565_out <= {rgb565_stage3[15:5], ~rgb565_stage3[4], rgb565_stage3[3:0]};
                    4'h6: rgb565_out <= {rgb565_stage3[15:6], ~rgb565_stage3[5], rgb565_stage3[4:0]};
                    4'h7: rgb565_out <= {rgb565_stage3[15:7], ~rgb565_stage3[6], rgb565_stage3[5:0]};
                    4'h8: rgb565_out <= {rgb565_stage3[15:8], ~rgb565_stage3[7], rgb565_stage3[6:0]};
                    4'h9: rgb565_out <= {rgb565_stage3[15:9], ~rgb565_stage3[8], rgb565_stage3[7:0]};
                    4'hA: rgb565_out <= {rgb565_stage3[15:10], ~rgb565_stage3[9], rgb565_stage3[8:0]};
                    4'hB: rgb565_out <= {rgb565_stage3[15:11], ~rgb565_stage3[10], rgb565_stage3[9:0]};
                    4'hC: rgb565_out <= {rgb565_stage3[15:12], ~rgb565_stage3[11], rgb565_stage3[10:0]};
                    4'hD: rgb565_out <= {rgb565_stage3[15:13], ~rgb565_stage3[12], rgb565_stage3[11:0]};
                    4'hE: rgb565_out <= {rgb565_stage3[15:14], ~rgb565_stage3[13], rgb565_stage3[12:0]};
                    4'hF: rgb565_out <= {~rgb565_stage3[14], rgb565_stage3[13:0]};
                    default: rgb565_out <= rgb565_stage3;
                endcase
            end else begin
                rgb565_out <= rgb565_stage3;
            end
        end else if (data_valid_stage3) begin
            rgb565_out <= rgb565_stage3;
        end
    end
endmodule