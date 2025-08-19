//SystemVerilog
module CRC_Compress #(
    parameter POLY = 32'h04C11DB7
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire valid_in,
    input wire [31:0] data,
    output reg valid_out,
    output reg [31:0] crc
);

    // Pipeline stage registers for data - increased from 4 to 8 stages
    reg [31:0] data_stage1, data_stage2, data_stage3, data_stage4;
    reg [31:0] data_stage5, data_stage6, data_stage7, data_stage8;
    
    // Pipeline stage registers for CRC calculation - increased from 4 to 8 stages
    reg [31:0] crc_stage1, crc_stage2, crc_stage3, crc_stage4;
    reg [31:0] crc_stage5, crc_stage6, crc_stage7;
    
    // Pipeline control signals - increased from 4 to 8 stages
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg valid_stage5, valid_stage6, valid_stage7, valid_stage8;
    
    // Internal calculation wires for each stage - increased from 4 to 8 stages
    wire [31:0] crc_next_stage1, crc_next_stage2, crc_next_stage3, crc_next_stage4;
    wire [31:0] crc_next_stage5, crc_next_stage6, crc_next_stage7, crc_next_stage8;
    wire xor_bit_stage1, xor_bit_stage2, xor_bit_stage3, xor_bit_stage4;
    wire xor_bit_stage5, xor_bit_stage6, xor_bit_stage7, xor_bit_stage8;
    
    // Stage 1 calculation - each stage now processes fewer bits
    assign xor_bit_stage1 = crc[31] ^ data[31];
    assign crc_next_stage1 = {crc[23:0], 1'b0} ^ (xor_bit_stage1 ? POLY : 32'h0);
    
    // Stage 2 calculation
    assign xor_bit_stage2 = crc_stage1[31] ^ data_stage1[30];
    assign crc_next_stage2 = {crc_stage1[23:0], 1'b0} ^ (xor_bit_stage2 ? POLY : 32'h0);
    
    // Stage 3 calculation
    assign xor_bit_stage3 = crc_stage2[31] ^ data_stage2[29];
    assign crc_next_stage3 = {crc_stage2[23:0], 1'b0} ^ (xor_bit_stage3 ? POLY : 32'h0);
    
    // Stage 4 calculation
    assign xor_bit_stage4 = crc_stage3[31] ^ data_stage3[28];
    assign crc_next_stage4 = {crc_stage3[23:0], 1'b0} ^ (xor_bit_stage4 ? POLY : 32'h0);
    
    // Stage 5 calculation - additional stages
    assign xor_bit_stage5 = crc_stage4[31] ^ data_stage4[27];
    assign crc_next_stage5 = {crc_stage4[23:0], 1'b0} ^ (xor_bit_stage5 ? POLY : 32'h0);
    
    // Stage 6 calculation
    assign xor_bit_stage6 = crc_stage5[31] ^ data_stage5[26];
    assign crc_next_stage6 = {crc_stage5[23:0], 1'b0} ^ (xor_bit_stage6 ? POLY : 32'h0);
    
    // Stage 7 calculation
    assign xor_bit_stage7 = crc_stage6[31] ^ data_stage6[25];
    assign crc_next_stage7 = {crc_stage6[23:0], 1'b0} ^ (xor_bit_stage7 ? POLY : 32'h0);
    
    // Stage 8 calculation
    assign xor_bit_stage8 = crc_stage7[31] ^ data_stage7[24];
    assign crc_next_stage8 = {crc_stage7[23:0], 1'b0} ^ (xor_bit_stage8 ? POLY : 32'h0);
    
    // Pipeline registers update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            data_stage1 <= 32'h0;
            data_stage2 <= 32'h0;
            data_stage3 <= 32'h0;
            data_stage4 <= 32'h0;
            data_stage5 <= 32'h0;
            data_stage6 <= 32'h0;
            data_stage7 <= 32'h0;
            data_stage8 <= 32'h0;
            
            crc_stage1 <= 32'h0;
            crc_stage2 <= 32'h0;
            crc_stage3 <= 32'h0;
            crc_stage4 <= 32'h0;
            crc_stage5 <= 32'h0;
            crc_stage6 <= 32'h0;
            crc_stage7 <= 32'h0;
            
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
            valid_stage5 <= 1'b0;
            valid_stage6 <= 1'b0;
            valid_stage7 <= 1'b0;
            valid_stage8 <= 1'b0;
            
            valid_out <= 1'b0;
            crc <= 32'h0;
        end
        else if (en) begin
            // Stage 1
            data_stage1 <= data;
            crc_stage1 <= crc_next_stage1;
            valid_stage1 <= valid_in;
            
            // Stage 2
            data_stage2 <= data_stage1;
            crc_stage2 <= crc_next_stage2;
            valid_stage2 <= valid_stage1;
            
            // Stage 3
            data_stage3 <= data_stage2;
            crc_stage3 <= crc_next_stage3;
            valid_stage3 <= valid_stage2;
            
            // Stage 4
            data_stage4 <= data_stage3;
            crc_stage4 <= crc_next_stage4;
            valid_stage4 <= valid_stage3;
            
            // Stage 5
            data_stage5 <= data_stage4;
            crc_stage5 <= crc_next_stage5;
            valid_stage5 <= valid_stage4;
            
            // Stage 6
            data_stage6 <= data_stage5;
            crc_stage6 <= crc_next_stage6;
            valid_stage6 <= valid_stage5;
            
            // Stage 7
            data_stage7 <= data_stage6;
            crc_stage7 <= crc_next_stage7;
            valid_stage7 <= valid_stage6;
            
            // Stage 8
            data_stage8 <= data_stage7;
            crc <= crc_next_stage8;
            valid_out <= valid_stage7;
        end
    end

endmodule