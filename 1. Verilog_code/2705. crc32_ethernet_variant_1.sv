//SystemVerilog
module crc32_ethernet (
    input clk, rst,
    input [31:0] data_in,
    output reg [31:0] crc_out
);
    parameter POLY = 32'h04C11DB7;
    
    // Stage 1: Data reversal
    reg [31:0] data_rev_stage1;
    always @(posedge clk) begin
        if (rst) begin
            data_rev_stage1 <= 32'h0;
        end else begin
            data_rev_stage1[0] <= data_in[31];
            data_rev_stage1[1] <= data_in[30];
            data_rev_stage1[2] <= data_in[29];
            data_rev_stage1[3] <= data_in[28];
            data_rev_stage1[4] <= data_in[27];
            data_rev_stage1[5] <= data_in[26];
            data_rev_stage1[6] <= data_in[25];
            data_rev_stage1[7] <= data_in[24];
            data_rev_stage1[8] <= data_in[23];
            data_rev_stage1[9] <= data_in[22];
            data_rev_stage1[10] <= data_in[21];
            data_rev_stage1[11] <= data_in[20];
            data_rev_stage1[12] <= data_in[19];
            data_rev_stage1[13] <= data_in[18];
            data_rev_stage1[14] <= data_in[17];
            data_rev_stage1[15] <= data_in[16];
            data_rev_stage1[16] <= data_in[15];
            data_rev_stage1[17] <= data_in[14];
            data_rev_stage1[18] <= data_in[13];
            data_rev_stage1[19] <= data_in[12];
            data_rev_stage1[20] <= data_in[11];
            data_rev_stage1[21] <= data_in[10];
            data_rev_stage1[22] <= data_in[9];
            data_rev_stage1[23] <= data_in[8];
            data_rev_stage1[24] <= data_in[7];
            data_rev_stage1[25] <= data_in[6];
            data_rev_stage1[26] <= data_in[5];
            data_rev_stage1[27] <= data_in[4];
            data_rev_stage1[28] <= data_in[3];
            data_rev_stage1[29] <= data_in[2];
            data_rev_stage1[30] <= data_in[1];
            data_rev_stage1[31] <= data_in[0];
        end
    end
    
    // Stage 2: XOR with previous CRC
    reg [31:0] crc_xord_stage2;
    always @(posedge clk) begin
        if (rst) begin
            crc_xord_stage2 <= 32'h0;
        end else begin
            crc_xord_stage2 <= crc_out ^ data_rev_stage1;
        end
    end
    
    // Split POLY gate computation into two pipeline stages to reduce critical path
    reg [31:0] poly_mask_stage2;
    always @(posedge clk) begin
        if (rst) begin
            poly_mask_stage2 <= 32'h0;
        end else begin
            poly_mask_stage2 <= {32{crc_xord_stage2[31]}} & POLY;
        end
    end
    
    // Stage 3: First part of CRC calculation (bits 0-7)
    reg [7:0] next_val_stage3_low;
    reg [31:0] crc_xord_stage3;
    always @(posedge clk) begin
        if (rst) begin
            next_val_stage3_low <= 8'h0;
            crc_xord_stage3 <= 32'h0;
        end else begin
            crc_xord_stage3 <= crc_xord_stage2;
            
            next_val_stage3_low[0] <= crc_xord_stage2[31] ^ poly_mask_stage2[0];
            next_val_stage3_low[1] <= crc_xord_stage2[31] ^ crc_xord_stage2[0] ^ poly_mask_stage2[1];
            next_val_stage3_low[2] <= crc_xord_stage2[31] ^ crc_xord_stage2[1] ^ poly_mask_stage2[2];
            next_val_stage3_low[3] <= crc_xord_stage2[2] ^ poly_mask_stage2[3];
            next_val_stage3_low[4] <= crc_xord_stage2[3] ^ poly_mask_stage2[4];
            next_val_stage3_low[5] <= crc_xord_stage2[4] ^ poly_mask_stage2[5];
            next_val_stage3_low[6] <= crc_xord_stage2[5] ^ poly_mask_stage2[6];
            next_val_stage3_low[7] <= crc_xord_stage2[6] ^ poly_mask_stage2[7];
        end
    end
    
    // Pipeline register for poly mask in stage 3
    reg [31:0] poly_mask_stage3;
    always @(posedge clk) begin
        if (rst) begin
            poly_mask_stage3 <= 32'h0;
        end else begin
            poly_mask_stage3 <= poly_mask_stage2;
        end
    end
    
    // Stage 4: Second part of CRC calculation (bits 8-15)
    reg [7:0] next_val_stage3_low_reg;
    reg [7:0] next_val_stage4_mid;
    reg [31:0] crc_xord_stage4;
    always @(posedge clk) begin
        if (rst) begin
            next_val_stage3_low_reg <= 8'h0;
            next_val_stage4_mid <= 8'h0;
            crc_xord_stage4 <= 32'h0;
        end else begin
            next_val_stage3_low_reg <= next_val_stage3_low;
            crc_xord_stage4 <= crc_xord_stage3;
            
            next_val_stage4_mid[0] <= crc_xord_stage3[7] ^ poly_mask_stage3[8];
            next_val_stage4_mid[1] <= crc_xord_stage3[8] ^ poly_mask_stage3[9];
            next_val_stage4_mid[2] <= crc_xord_stage3[9] ^ poly_mask_stage3[10];
            next_val_stage4_mid[3] <= crc_xord_stage3[10] ^ poly_mask_stage3[11];
            next_val_stage4_mid[4] <= crc_xord_stage3[11] ^ poly_mask_stage3[12];
            next_val_stage4_mid[5] <= crc_xord_stage3[12] ^ poly_mask_stage3[13];
            next_val_stage4_mid[6] <= crc_xord_stage3[13] ^ poly_mask_stage3[14];
            next_val_stage4_mid[7] <= crc_xord_stage3[14] ^ poly_mask_stage3[15];
        end
    end
    
    // Pipeline register for poly mask in stage 4
    reg [31:0] poly_mask_stage4;
    always @(posedge clk) begin
        if (rst) begin
            poly_mask_stage4 <= 32'h0;
        end else begin
            poly_mask_stage4 <= poly_mask_stage3;
        end
    end
    
    // Stage 5: Third part of CRC calculation (bits 16-23)
    reg [7:0] next_val_stage3_low_reg2;
    reg [7:0] next_val_stage4_mid_reg;
    reg [7:0] next_val_stage5_high;
    reg [31:0] crc_xord_stage5;
    always @(posedge clk) begin
        if (rst) begin
            next_val_stage3_low_reg2 <= 8'h0;
            next_val_stage4_mid_reg <= 8'h0;
            next_val_stage5_high <= 8'h0;
            crc_xord_stage5 <= 32'h0;
        end else begin
            next_val_stage3_low_reg2 <= next_val_stage3_low_reg;
            next_val_stage4_mid_reg <= next_val_stage4_mid;
            crc_xord_stage5 <= crc_xord_stage4;
            
            next_val_stage5_high[0] <= crc_xord_stage4[15] ^ poly_mask_stage4[16];
            next_val_stage5_high[1] <= crc_xord_stage4[16] ^ poly_mask_stage4[17];
            next_val_stage5_high[2] <= crc_xord_stage4[17] ^ poly_mask_stage4[18];
            next_val_stage5_high[3] <= crc_xord_stage4[18] ^ poly_mask_stage4[19];
            next_val_stage5_high[4] <= crc_xord_stage4[19] ^ poly_mask_stage4[20];
            next_val_stage5_high[5] <= crc_xord_stage4[20] ^ poly_mask_stage4[21];
            next_val_stage5_high[6] <= crc_xord_stage4[21] ^ poly_mask_stage4[22];
            next_val_stage5_high[7] <= crc_xord_stage4[22] ^ poly_mask_stage4[23];
        end
    end
    
    // Pipeline register for poly mask in stage 5
    reg [31:0] poly_mask_stage5;
    always @(posedge clk) begin
        if (rst) begin
            poly_mask_stage5 <= 32'h0;
        end else begin
            poly_mask_stage5 <= poly_mask_stage4;
        end
    end
    
    // Stage 6: Final part of CRC calculation (bits 24-31)
    reg [7:0] next_val_stage3_low_reg3;
    reg [7:0] next_val_stage4_mid_reg2;
    reg [7:0] next_val_stage5_high_reg;
    reg [7:0] next_val_stage6_top;
    always @(posedge clk) begin
        if (rst) begin
            next_val_stage3_low_reg3 <= 8'h0;
            next_val_stage4_mid_reg2 <= 8'h0;
            next_val_stage5_high_reg <= 8'h0;
            next_val_stage6_top <= 8'h0;
        end else begin
            next_val_stage3_low_reg3 <= next_val_stage3_low_reg2;
            next_val_stage4_mid_reg2 <= next_val_stage4_mid_reg;
            next_val_stage5_high_reg <= next_val_stage5_high;
            
            next_val_stage6_top[0] <= crc_xord_stage5[23] ^ poly_mask_stage5[24];
            next_val_stage6_top[1] <= crc_xord_stage5[24] ^ poly_mask_stage5[25];
            next_val_stage6_top[2] <= crc_xord_stage5[25] ^ poly_mask_stage5[26];
            next_val_stage6_top[3] <= crc_xord_stage5[26] ^ poly_mask_stage5[27];
            next_val_stage6_top[4] <= crc_xord_stage5[27] ^ poly_mask_stage5[28];
            next_val_stage6_top[5] <= crc_xord_stage5[28] ^ poly_mask_stage5[29];
            next_val_stage6_top[6] <= crc_xord_stage5[29] ^ poly_mask_stage5[30];
            next_val_stage6_top[7] <= crc_xord_stage5[30] ^ poly_mask_stage5[31];
        end
    end
    
    // Final stage: Combine all parts and update CRC output
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 32'hFFFFFFFF;
        end else begin
            crc_out <= {next_val_stage6_top, next_val_stage5_high_reg, 
                        next_val_stage4_mid_reg2, next_val_stage3_low_reg3};
        end
    end
endmodule