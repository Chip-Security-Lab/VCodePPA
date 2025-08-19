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

    reg [7:0] data_in_stage1, data_in_stage2, data_in_stage3;
    reg data_valid_stage1, data_valid_stage2, data_valid_stage3;
    reg [31:0] calc_crc_stage1, calc_crc_stage2, calc_crc_stage3;
    reg [31:0] next_crc_stage1, next_crc_stage2, next_crc_stage3;
    
    always @(*) begin
        // Stage 1 computation
        next_crc_stage1 = calc_crc_stage1;
        if (data_valid_stage1) begin
            next_crc_stage1[0] = calc_crc_stage1[24] ^ calc_crc_stage1[30] ^ data_in_stage1[0] ^ data_in_stage1[6];
            next_crc_stage1[1] = calc_crc_stage1[24] ^ calc_crc_stage1[25] ^ calc_crc_stage1[30] ^ calc_crc_stage1[31] ^ 
                               data_in_stage1[0] ^ data_in_stage1[1] ^ data_in_stage1[6] ^ data_in_stage1[7];
            next_crc_stage1[2] = calc_crc_stage1[25] ^ calc_crc_stage1[26] ^ calc_crc_stage1[31] ^ 
                               data_in_stage1[1] ^ data_in_stage1[2] ^ data_in_stage1[7];
            next_crc_stage1[3] = calc_crc_stage1[26] ^ calc_crc_stage1[27] ^ 
                               data_in_stage1[2] ^ data_in_stage1[3];
        end

        // Stage 2 computation
        next_crc_stage2 = calc_crc_stage2;
        if (data_valid_stage2) begin
            next_crc_stage2[4] = calc_crc_stage2[24] ^ calc_crc_stage2[27] ^ calc_crc_stage2[28] ^ calc_crc_stage2[30] ^ 
                               data_in_stage2[0] ^ data_in_stage2[3] ^ data_in_stage2[4] ^ data_in_stage2[6];
            next_crc_stage2[5] = calc_crc_stage2[24] ^ calc_crc_stage2[25] ^ calc_crc_stage2[28] ^ calc_crc_stage2[29] ^ 
                               calc_crc_stage2[30] ^ calc_crc_stage2[31] ^ data_in_stage2[0] ^ data_in_stage2[1] ^ 
                               data_in_stage2[4] ^ data_in_stage2[5] ^ data_in_stage2[6] ^ data_in_stage2[7];
            next_crc_stage2[31:6] = calc_crc_stage2[31:6];
        end

        // Stage 3 computation
        next_crc_stage3 = calc_crc_stage3;
        if (data_valid_stage3) begin
            next_crc_stage3 = next_crc_stage2;
        end
    end

    generate
        if (SYNC_MODE == 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    {data_in_stage1, data_in_stage2, data_in_stage3} <= {3{8'h0}};
                    {data_valid_stage1, data_valid_stage2, data_valid_stage3} <= 3'b0;
                    {calc_crc_stage1, calc_crc_stage2, calc_crc_stage3} <= {3{32'hFFFFFFFF}};
                    crc_error <= 0;
                    calc_crc <= 32'hFFFFFFFF;
                end else begin
                    data_in_stage1 <= data_in;
                    data_valid_stage1 <= data_valid;
                    calc_crc_stage1 <= calc_crc;
                    
                    data_in_stage2 <= data_in_stage1;
                    data_valid_stage2 <= data_valid_stage1;
                    calc_crc_stage2 <= next_crc_stage1;
                    
                    data_in_stage3 <= data_in_stage2;
                    data_valid_stage3 <= data_valid_stage2;
                    calc_crc_stage3 <= next_crc_stage2;
                    
                    calc_crc <= next_crc_stage3;
                    crc_error <= (next_crc_stage3 != 32'h0) && data_valid_stage3;
                end
            end
        end else begin
            always @(*) begin
                calc_crc = next_crc_stage3;
                crc_error = (next_crc_stage3 != 32'h0) && data_valid_stage3;
            end
        end
    endgenerate
endmodule