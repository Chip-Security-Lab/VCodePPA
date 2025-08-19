//SystemVerilog
module integrity_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    output reg [7:0] crc_value,
    output reg integrity_error
);
    parameter [7:0] POLY = 8'hD5;
    parameter [7:0] EXPECTED_CRC = 8'h00;
    
    // Pipeline stage registers
    reg [7:0] crc_stage1, crc_stage2, crc_stage3;
    reg [7:0] shadow_crc_stage1, shadow_crc_stage2, shadow_crc_stage3;
    
    // Intermediate calculation signals
    reg crc_xor_bit_stage1, shadow_xor_bit_stage1;
    reg [7:0] crc_poly_sel_stage2, shadow_poly_sel_stage2;
    reg [7:0] crc_shift_stage1, shadow_shift_stage1;
    
    // Pipeline validity tracking
    reg data_valid_stage1, data_valid_stage2, data_valid_stage3;
    
    // Stage 1: Calculate XOR bit and prepare shift
    always @(posedge clk) begin
        if (rst) begin
            crc_stage1 <= 8'h00;
            shadow_crc_stage1 <= 8'h00;
            crc_xor_bit_stage1 <= 1'b0;
            shadow_xor_bit_stage1 <= 1'b0;
            crc_shift_stage1 <= 8'h00;
            shadow_shift_stage1 <= 8'h00;
            data_valid_stage1 <= 1'b0;
        end else begin
            data_valid_stage1 <= data_valid;
            if (data_valid) begin
                crc_stage1 <= crc_value;
                shadow_crc_stage1 <= shadow_crc_stage3; // Feedback from last stage
                
                crc_xor_bit_stage1 <= crc_value[7] ^ data[0];
                shadow_xor_bit_stage1 <= shadow_crc_stage3[7] ^ data[0];
                
                crc_shift_stage1 <= {crc_value[6:0], 1'b0};
                shadow_shift_stage1 <= {shadow_crc_stage3[6:0], 1'b0};
            end
        end
    end
    
    // Stage 2: Polynomial selection and XOR operation
    always @(posedge clk) begin
        if (rst) begin
            crc_stage2 <= 8'h00;
            shadow_crc_stage2 <= 8'h00;
            crc_poly_sel_stage2 <= 8'h00;
            shadow_poly_sel_stage2 <= 8'h00;
            data_valid_stage2 <= 1'b0;
        end else begin
            data_valid_stage2 <= data_valid_stage1;
            if (data_valid_stage1) begin
                crc_poly_sel_stage2 <= crc_xor_bit_stage1 ? POLY : 8'h00;
                shadow_poly_sel_stage2 <= shadow_xor_bit_stage1 ? POLY : 8'h00;
                
                crc_stage2 <= crc_shift_stage1;
                shadow_crc_stage2 <= shadow_shift_stage1;
            end
        end
    end
    
    // Stage 3: Final XOR and error detection
    always @(posedge clk) begin
        if (rst) begin
            crc_stage3 <= 8'h00;
            shadow_crc_stage3 <= 8'h00;
            data_valid_stage3 <= 1'b0;
        end else begin
            data_valid_stage3 <= data_valid_stage2;
            if (data_valid_stage2) begin
                crc_stage3 <= crc_stage2 ^ crc_poly_sel_stage2;
                shadow_crc_stage3 <= shadow_crc_stage2 ^ shadow_poly_sel_stage2;
            end
        end
    end
    
    // Final output calculation
    always @(posedge clk) begin
        if (rst) begin
            crc_value <= 8'h00;
            integrity_error <= 1'b0;
        end else if (data_valid_stage3) begin
            crc_value <= crc_stage3;
            integrity_error <= (crc_stage3 != shadow_crc_stage3);
        end
    end
endmodule