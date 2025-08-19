//SystemVerilog
module MIPI_CRC_Checker #(
    parameter POLYNOMIAL = 32'h04C11DB7,
    parameter SYNC_MODE = 1
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg crc_error,
    output reg [31:0] calc_crc
);

    // Pipeline registers
    reg [31:0] next_crc_stage1;
    reg [31:0] next_crc_stage2;
    reg [31:0] next_crc_stage3;
    reg [31:0] next_crc_stage4;
    reg data_valid_stage1;
    reg data_valid_stage2;
    reg data_valid_stage3;
    reg data_valid_stage4;
    
    // Stage 1: First level of CRC calculation - bits 0-3
    always @(*) begin
        next_crc_stage1 = calc_crc;
        if (data_valid) begin
            next_crc_stage1[0] = calc_crc[24] ^ calc_crc[30] ^ data_in[0] ^ data_in[6];
            next_crc_stage1[1] = calc_crc[24] ^ calc_crc[25] ^ calc_crc[30] ^ calc_crc[31] ^ 
                                data_in[0] ^ data_in[1] ^ data_in[6] ^ data_in[7];
            next_crc_stage1[2] = calc_crc[25] ^ calc_crc[26] ^ calc_crc[31] ^ 
                                data_in[1] ^ data_in[2] ^ data_in[7];
            next_crc_stage1[3] = calc_crc[26] ^ calc_crc[27] ^ 
                                data_in[2] ^ data_in[3];
        end
    end

    // Stage 2: Second level of CRC calculation - bits 4-5
    always @(*) begin
        next_crc_stage2 = next_crc_stage1;
        if (data_valid_stage1) begin
            next_crc_stage2[4] = next_crc_stage1[24] ^ next_crc_stage1[27] ^ 
                                next_crc_stage1[28] ^ next_crc_stage1[30] ^ 
                                data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[6];
            next_crc_stage2[5] = next_crc_stage1[24] ^ next_crc_stage1[25] ^ 
                                next_crc_stage1[28] ^ next_crc_stage1[29] ^ 
                                next_crc_stage1[30] ^ next_crc_stage1[31] ^ 
                                data_in[0] ^ data_in[1] ^ data_in[4] ^ 
                                data_in[5] ^ data_in[6] ^ data_in[7];
        end
    end

    // Stage 3: Third level of CRC calculation - bits 6-15
    always @(*) begin
        next_crc_stage3 = next_crc_stage2;
        if (data_valid_stage2) begin
            next_crc_stage3[6] = next_crc_stage2[25] ^ next_crc_stage2[26] ^ 
                                next_crc_stage2[29] ^ next_crc_stage2[30] ^ 
                                data_in[1] ^ data_in[2] ^ data_in[5] ^ data_in[6];
            next_crc_stage3[7] = next_crc_stage2[26] ^ next_crc_stage2[27] ^ 
                                next_crc_stage2[30] ^ next_crc_stage2[31] ^ 
                                data_in[2] ^ data_in[3] ^ data_in[6] ^ data_in[7];
            next_crc_stage3[8] = next_crc_stage2[27] ^ next_crc_stage2[28] ^ 
                                next_crc_stage2[31] ^ 
                                data_in[3] ^ data_in[4] ^ data_in[7];
            next_crc_stage3[9] = next_crc_stage2[28] ^ next_crc_stage2[29] ^ 
                                data_in[4] ^ data_in[5];
            next_crc_stage3[10] = next_crc_stage2[29] ^ next_crc_stage2[30] ^ 
                                data_in[5] ^ data_in[6];
            next_crc_stage3[11] = next_crc_stage2[30] ^ next_crc_stage2[31] ^ 
                                data_in[6] ^ data_in[7];
            next_crc_stage3[12] = next_crc_stage2[31] ^ data_in[7];
            next_crc_stage3[13] = next_crc_stage2[24] ^ next_crc_stage2[25] ^ 
                                data_in[0] ^ data_in[1];
            next_crc_stage3[14] = next_crc_stage2[25] ^ next_crc_stage2[26] ^ 
                                data_in[1] ^ data_in[2];
            next_crc_stage3[15] = next_crc_stage2[26] ^ next_crc_stage2[27] ^ 
                                data_in[2] ^ data_in[3];
        end
    end

    // Stage 4: Fourth level of CRC calculation - bits 16-31
    always @(*) begin
        next_crc_stage4 = next_crc_stage3;
        if (data_valid_stage3) begin
            next_crc_stage4[16] = next_crc_stage3[27] ^ next_crc_stage3[28] ^ 
                                data_in[3] ^ data_in[4];
            next_crc_stage4[17] = next_crc_stage3[28] ^ next_crc_stage3[29] ^ 
                                data_in[4] ^ data_in[5];
            next_crc_stage4[18] = next_crc_stage3[29] ^ next_crc_stage3[30] ^ 
                                data_in[5] ^ data_in[6];
            next_crc_stage4[19] = next_crc_stage3[30] ^ next_crc_stage3[31] ^ 
                                data_in[6] ^ data_in[7];
            next_crc_stage4[20] = next_crc_stage3[31] ^ data_in[7];
            next_crc_stage4[21] = next_crc_stage3[24] ^ next_crc_stage3[25] ^ 
                                data_in[0] ^ data_in[1];
            next_crc_stage4[22] = next_crc_stage3[25] ^ next_crc_stage3[26] ^ 
                                data_in[1] ^ data_in[2];
            next_crc_stage4[23] = next_crc_stage3[26] ^ next_crc_stage3[27] ^ 
                                data_in[2] ^ data_in[3];
            next_crc_stage4[24] = next_crc_stage3[27] ^ next_crc_stage3[28] ^ 
                                data_in[3] ^ data_in[4];
            next_crc_stage4[25] = next_crc_stage3[28] ^ next_crc_stage3[29] ^ 
                                data_in[4] ^ data_in[5];
            next_crc_stage4[26] = next_crc_stage3[29] ^ next_crc_stage3[30] ^ 
                                data_in[5] ^ data_in[6];
            next_crc_stage4[27] = next_crc_stage3[30] ^ next_crc_stage3[31] ^ 
                                data_in[6] ^ data_in[7];
            next_crc_stage4[28] = next_crc_stage3[31] ^ data_in[7];
            next_crc_stage4[29] = next_crc_stage3[24] ^ next_crc_stage3[25] ^ 
                                data_in[0] ^ data_in[1];
            next_crc_stage4[30] = next_crc_stage3[25] ^ next_crc_stage3[26] ^ 
                                data_in[1] ^ data_in[2];
            next_crc_stage4[31] = next_crc_stage3[26] ^ next_crc_stage3[27] ^ 
                                data_in[2] ^ data_in[3];
        end
    end

    // Pipeline registers update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_stage1 <= 1'b0;
            data_valid_stage2 <= 1'b0;
            data_valid_stage3 <= 1'b0;
            data_valid_stage4 <= 1'b0;
        end else begin
            data_valid_stage1 <= data_valid;
            data_valid_stage2 <= data_valid_stage1;
            data_valid_stage3 <= data_valid_stage2;
            data_valid_stage4 <= data_valid_stage3;
        end
    end

    // Final stage and output generation
    generate
        if (SYNC_MODE == 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    calc_crc <= 32'hFFFFFFFF;
                    crc_error <= 0;
                end else if (data_valid_stage4) begin
                    calc_crc <= next_crc_stage4;
                    crc_error <= (next_crc_stage4 != 32'h0);
                end
            end
        end else begin
            always @(*) begin
                calc_crc = next_crc_stage4;
                crc_error = (next_crc_stage4 != 32'h0) && data_valid_stage4;
            end
        end
    endgenerate

endmodule