//SystemVerilog
`timescale 1ns / 1ps
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
    
    // Pipeline stage registers
    // Stage 1: RGB conversion
    reg [15:0] rgb565_stage1;
    reg data_valid_stage1;
    reg ecc_enable_stage1;
    
    // Stage 2: Hamming code generation
    reg [15:0] rgb565_stage2;
    reg [3:0] ecc_bits_stage2;
    reg data_valid_stage2;
    reg ecc_enable_stage2;
    
    // Stage 3: Syndrome calculation
    reg [15:0] rgb565_stage3;
    reg [3:0] ecc_bits_stage3;
    reg [3:0] syndrome_stage3;
    reg data_valid_stage3;
    reg ecc_enable_stage3;
    
    // Stage 4: Error correction
    reg [15:0] rgb565_stage4;
    reg [3:0] ecc_bits_stage4;
    reg [3:0] syndrome_stage4;
    reg data_valid_stage4;
    reg ecc_enable_stage4;
    
    // Internal wires for cleaner connections between stages
    wire [15:0] rgb565_conv;
    wire [3:0] hamming_code;
    wire [3:0] syndrome;
    wire [15:0] corrected_data;
    
    // RGB888 to RGB565 conversion logic
    assign rgb565_conv = data_valid ? {rgb_in[23:19], rgb_in[15:10], rgb_in[7:3]} : 16'h0000;
    
    // Stage 1: RGB conversion register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_stage1 <= 16'h0000;
            data_valid_stage1 <= 1'b0;
            ecc_enable_stage1 <= 1'b0;
        end else begin
            rgb565_stage1 <= rgb565_conv;
            data_valid_stage1 <= data_valid;
            ecc_enable_stage1 <= ecc_enable;
        end
    end
    
    // Hamming code generation logic
    assign hamming_code = (data_valid_stage1 && ecc_enable_stage1) ? gen_hamming(rgb565_stage1) : 4'h0;
    
    // Stage 2: Hamming code generation register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_stage2 <= 16'h0000;
            ecc_bits_stage2 <= 4'h0;
            data_valid_stage2 <= 1'b0;
            ecc_enable_stage2 <= 1'b0;
        end else begin
            rgb565_stage2 <= rgb565_stage1;
            ecc_bits_stage2 <= hamming_code;
            data_valid_stage2 <= data_valid_stage1;
            ecc_enable_stage2 <= ecc_enable_stage1;
        end
    end
    
    // Syndrome calculation logic
    assign syndrome = (data_valid_stage2 && ecc_enable_stage2) ? 
                     ecc_bits_stage2 ^ gen_hamming(rgb565_stage2) : 4'h0;
    
    // Stage 3: Syndrome calculation register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_stage3 <= 16'h0000;
            ecc_bits_stage3 <= 4'h0;
            syndrome_stage3 <= 4'h0;
            data_valid_stage3 <= 1'b0;
            ecc_enable_stage3 <= 1'b0;
        end else begin
            rgb565_stage3 <= rgb565_stage2;
            ecc_bits_stage3 <= ecc_bits_stage2;
            syndrome_stage3 <= syndrome;
            data_valid_stage3 <= data_valid_stage2;
            ecc_enable_stage3 <= ecc_enable_stage2;
        end
    end
    
    // Error correction logic
    assign corrected_data = correct_error(rgb565_stage3, syndrome_stage3);
    
    // Stage 4: Error correction register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_stage4 <= 16'h0000;
            ecc_bits_stage4 <= 4'h0;
            syndrome_stage4 <= 4'h0;
            data_valid_stage4 <= 1'b0;
            ecc_enable_stage4 <= 1'b0;
        end else begin
            rgb565_stage4 <= rgb565_stage3;
            ecc_bits_stage4 <= ecc_bits_stage3;
            syndrome_stage4 <= syndrome_stage3;
            data_valid_stage4 <= data_valid_stage3;
            ecc_enable_stage4 <= ecc_enable_stage3;
        end
    end
    
    // Output generation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            protected_out <= 20'h00000;
            error_detected <= 1'b0;
            rgb565_out <= 16'h0000;
        end else if (data_valid_stage4) begin
            if (ecc_enable_stage4) begin
                protected_out <= {rgb565_stage4, ecc_bits_stage4};
                error_detected <= (syndrome_stage4 != 4'h0);
                rgb565_out <= corrected_data;
            end else begin
                protected_out <= {rgb565_stage4, 4'h0};
                error_detected <= 1'b0;
                rgb565_out <= rgb565_stage4;
            end
        end
    end
    
endmodule