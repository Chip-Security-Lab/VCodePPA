//SystemVerilog
module CRC_Filter #(parameter POLY=16'h8005) (
    input clk,
    input rst,
    input valid_in,
    input [7:0] data_in,
    output reg valid_out,
    output reg [15:0] crc_out
);
    // Stage 1: Input registration and initial XOR
    reg [7:0] data_stage1;
    reg [15:0] crc_stage1;
    reg valid_stage1;
    
    wire [7:0] data_xor_stage1 = data_in ^ crc_out[15:8];
    wire [15:0] crc_next_stage1 = {crc_out[7:0], 8'h00} ^ (data_xor_stage1 << 8);
    
    // Stage 2: Polynomial masking and final XOR
    reg [15:0] crc_next_stage2;
    reg valid_stage2;
    
    wire [15:0] poly_mask_stage2 = POLY & {16{crc_next_stage2[15]}};
    wire [15:0] crc_final = crc_next_stage2 ^ poly_mask_stage2;
    
    // Pipeline registers and control logic
    always @(posedge clk) begin
        if (rst) begin
            // Reset all pipeline registers
            data_stage1 <= 8'h0;
            crc_stage1 <= 16'h0;
            valid_stage1 <= 1'b0;
            
            crc_next_stage2 <= 16'h0;
            valid_stage2 <= 1'b0;
            
            crc_out <= 16'h0;
            valid_out <= 1'b0;
        end else begin
            // Stage 1
            data_stage1 <= data_in;
            crc_stage1 <= crc_out;
            valid_stage1 <= valid_in;
            
            // Stage 2
            crc_next_stage2 <= crc_next_stage1;
            valid_stage2 <= valid_stage1;
            
            // Output stage
            crc_out <= crc_final;
            valid_out <= valid_stage2;
        end
    end
endmodule