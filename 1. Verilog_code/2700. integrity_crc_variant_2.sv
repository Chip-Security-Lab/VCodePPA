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
    
    // Stage 1 registers - Initial XOR and polynomial application
    reg [7:0] crc_stage1, shadow_crc_stage1;
    reg crc_bit_stage1, shadow_bit_stage1;
    reg data_valid_stage1;
    
    // Stage 2 registers - Shift operation
    reg [7:0] crc_stage2, shadow_crc_stage2;
    reg data_valid_stage2;
    
    // Stage 3 registers - Integrity check
    reg [7:0] crc_stage3, shadow_crc_stage3;
    
    // Combined pipeline stages with single always block
    always @(posedge clk) begin
        if (rst) begin
            // Reset all registers
            crc_bit_stage1 <= 1'b0;
            shadow_bit_stage1 <= 1'b0;
            crc_stage1 <= 8'h00;
            shadow_crc_stage1 <= 8'h00;
            data_valid_stage1 <= 1'b0;
            
            crc_stage2 <= 8'h00;
            shadow_crc_stage2 <= 8'h00;
            data_valid_stage2 <= 1'b0;
            
            crc_value <= 8'h00;
            shadow_crc_stage3 <= 8'h00;
            integrity_error <= 1'b0;
        end else begin
            // Stage 1: Compute XOR and polynomial application
            data_valid_stage1 <= data_valid;
            if (data_valid) begin
                crc_bit_stage1 <= crc_value[7] ^ data[0];
                shadow_bit_stage1 <= shadow_crc_stage3[7] ^ data[0];
                crc_stage1 <= crc_bit_stage1 ? POLY : 8'h00;
                shadow_crc_stage1 <= shadow_bit_stage1 ? POLY : 8'h00;
            end
            
            // Stage 2: Perform shift and XOR operations
            data_valid_stage2 <= data_valid_stage1;
            if (data_valid_stage1) begin
                crc_stage2 <= {crc_value[6:0], 1'b0} ^ crc_stage1;
                shadow_crc_stage2 <= {shadow_crc_stage3[6:0], 1'b0} ^ shadow_crc_stage1;
            end
            
            // Stage 3: Final output and integrity check
            if (data_valid_stage2) begin
                crc_value <= crc_stage2;
                shadow_crc_stage3 <= shadow_crc_stage2;
                integrity_error <= (crc_stage2 != shadow_crc_stage2);
            end
        end
    end
endmodule