//SystemVerilog
module eth_crc_gen (
    input wire [7:0] data_in,
    input wire crc_en,
    input wire crc_init,
    input wire clk,
    output wire [31:0] crc_out
);
    // Pipeline stage registers
    reg [31:0] crc_reg;           // Stage 1 register
    reg [31:0] crc_reg_stage2;    // Stage 2 register  
    reg [31:0] crc_reg_stage3;    // Stage 3 register
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    reg init_stage1, init_stage2;
    
    // Intermediate calculation results
    wire [31:0] next_crc;
    wire [31:0] byte_processed;
    wire [31:0] final_result;
    
    // Buffer registers for high fanout signals
    reg [31:0] crc_reg_buf1, crc_reg_buf2;
    reg [31:0] crc_reg_stage2_buf1, crc_reg_stage2_buf2;
    reg [31:0] next_crc_buf1, next_crc_buf2;
    
    // Bit operation buffer
    reg b0_buf1, b0_buf2;
    
    // Stage 1: Initialize and calculate next CRC
    always @(posedge clk) begin
        if (crc_init) begin
            crc_reg <= 32'hFFFFFFFF;
            valid_stage1 <= 1'b0;
            init_stage1 <= 1'b1;
        end
        else if (crc_en) begin
            crc_reg <= next_crc;
            valid_stage1 <= 1'b1;
            init_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= 1'b0;
            init_stage1 <= 1'b0;
        end
        
        // Buffer registers for high fanout signals
        crc_reg_buf1 <= crc_reg;
        crc_reg_buf2 <= crc_reg;
        b0_buf1 <= crc_reg[31];
        b0_buf2 <= crc_reg[31];
    end
    
    // Buffer for next_crc signal
    always @(posedge clk) begin
        next_crc_buf1 <= next_crc;
        next_crc_buf2 <= next_crc;
    end
    
    // Generate next CRC value (part of stage 1)
    // Use buffered signals to distribute fanout
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: crc_gen_loop_low
            assign next_crc[i] = crc_reg_buf1[24+i] ^ data_in[i] ^ b0_buf1;
        end
        for (i = 4; i < 8; i = i + 1) begin: crc_gen_loop_high
            assign next_crc[i] = crc_reg_buf2[24+i] ^ data_in[i] ^ b0_buf2;
        end
    endgenerate
    
    // Split assignment to reduce fanout
    assign next_crc[15:8] = crc_reg_buf1[7:0];
    assign next_crc[23:16] = crc_reg_buf1[15:8];
    assign next_crc[31:24] = crc_reg_buf2[23:16];
    
    // Stage 2: Prepare for bit reversal
    always @(posedge clk) begin
        crc_reg_stage2 <= crc_reg;
        valid_stage2 <= valid_stage1;
        init_stage2 <= init_stage1;
        
        // Buffer registers for high fanout signals
        crc_reg_stage2_buf1 <= crc_reg_stage2;
        crc_reg_stage2_buf2 <= crc_reg_stage2;
    end
    
    // Perform initial bit reorganization for stage 2
    // Split the bit assignments to use different buffers, reducing fanout
    wire [15:0] byte_processed_high, byte_processed_low;
    
    assign byte_processed_high = {
        crc_reg_stage2_buf1[24], crc_reg_stage2_buf1[25], crc_reg_stage2_buf1[26], crc_reg_stage2_buf1[27],
        crc_reg_stage2_buf1[28], crc_reg_stage2_buf1[29], crc_reg_stage2_buf1[30], crc_reg_stage2_buf1[31],
        crc_reg_stage2_buf1[16], crc_reg_stage2_buf1[17], crc_reg_stage2_buf1[18], crc_reg_stage2_buf1[19],
        crc_reg_stage2_buf1[20], crc_reg_stage2_buf1[21], crc_reg_stage2_buf1[22], crc_reg_stage2_buf1[23]
    };
    
    assign byte_processed_low = {
        crc_reg_stage2_buf2[8],  crc_reg_stage2_buf2[9],  crc_reg_stage2_buf2[10], crc_reg_stage2_buf2[11],
        crc_reg_stage2_buf2[12], crc_reg_stage2_buf2[13], crc_reg_stage2_buf2[14], crc_reg_stage2_buf2[15],
        crc_reg_stage2_buf2[0],  crc_reg_stage2_buf2[1],  crc_reg_stage2_buf2[2],  crc_reg_stage2_buf2[3],
        crc_reg_stage2_buf2[4],  crc_reg_stage2_buf2[5],  crc_reg_stage2_buf2[6],  crc_reg_stage2_buf2[7]
    };
    
    assign byte_processed = {byte_processed_high, byte_processed_low};
    
    // Stage 3: Final inversion
    always @(posedge clk) begin
        crc_reg_stage3 <= byte_processed;
        valid_stage3 <= valid_stage2;
    end
    
    // Invert all bits for final result (handled in combination logic to avoid an extra stage)
    assign final_result = ~crc_reg_stage3;
    
    // Output selection logic - handle special cases of reset and initialization
    assign crc_out = (init_stage2) ? ~32'hFFFFFFFF : final_result;
    
endmodule