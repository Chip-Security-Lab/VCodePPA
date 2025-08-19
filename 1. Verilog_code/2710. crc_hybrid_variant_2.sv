//SystemVerilog
module crc_hybrid #(parameter WIDTH=32)(
    input clk, rst_n, en,
    input [WIDTH-1:0] data,
    output reg [31:0] crc,
    output reg valid
);

    // Pipeline stage 1 registers
    reg [31:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [31:0] partial_crc_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [31:0] result_stage3;
    reg valid_stage3;
    
    // CRC polynomial constant
    localparam CRC_POLY = 32'h04C11DB7;
    
    // Bit-by-bit CRC calculation
    wire [31:0] stage2_crc_calc;
    wire [31:0] stage3_crc_calc[7:0];
    
    // Stage 1: Data input and initial processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 32'h0;
            valid_stage1 <= 1'b0;
        end else if (en) begin
            data_stage1 <= data[31:0];
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // First part of the CRC calculation (4 bits)
    assign stage2_crc_calc = data_stage1 ^ 
                           (data_stage1[31] ? {CRC_POLY[30:0], 1'b0} : 32'b0) ^
                           (data_stage1[30] ? {1'b0, CRC_POLY[30:0]} : 32'b0) ^
                           (data_stage1[29] ? {2'b0, CRC_POLY[30:1]} : 32'b0) ^
                           (data_stage1[28] ? {3'b0, CRC_POLY[30:2]} : 32'b0);

    // Stage 2: Process first 4 bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_crc_stage2 <= 32'h0;
            valid_stage2 <= 1'b0;
        end else begin
            partial_crc_stage2 <= stage2_crc_calc;
            valid_stage2 <= valid_stage1;
        end
    end

    // Process next 8 bits in parallel
    assign stage3_crc_calc[0] = partial_crc_stage2;
    
    genvar i;
    generate
        for (i = 0; i < 7; i = i + 1) begin : crc_bit_calc
            assign stage3_crc_calc[i+1] = {stage3_crc_calc[i][30:0], 1'b0} ^ 
                                       (stage3_crc_calc[i][31] ? CRC_POLY : 32'b0);
        end
    endgenerate

    // Stage 3: Complete CRC calculation for this chunk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage3 <= 32'h0;
            valid_stage3 <= 1'b0;
        end else begin
            result_stage3 <= (WIDTH > 32) ? stage3_crc_calc[7] : partial_crc_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Output stage with pipelining
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc <= 32'h0;
            valid <= 1'b0;
        end else begin
            crc <= result_stage3;
            valid <= valid_stage3;
        end
    end

endmodule