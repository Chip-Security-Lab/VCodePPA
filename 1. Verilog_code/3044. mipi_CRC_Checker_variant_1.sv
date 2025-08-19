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

    reg [31:0] next_crc;
    wire [7:0] data_xor;
    wire [31:0] crc_xor;
    wire [5:0] crc_bits;
    wire [5:0] data_bits;
    
    // Precompute XOR results
    assign data_xor = data_in ^ {calc_crc[30], calc_crc[31], 6'b0};
    assign crc_xor = {calc_crc[24:0], 7'b0} ^ {7'b0, calc_crc[31:7]};
    
    // Break down complex XOR expressions
    assign crc_bits[0] = calc_crc[24] ^ calc_crc[25] ^ calc_crc[28] ^ calc_crc[29] ^ calc_crc[30] ^ calc_crc[31];
    assign crc_bits[1] = calc_crc[24] ^ calc_crc[27] ^ calc_crc[28] ^ calc_crc[30];
    assign crc_bits[2] = calc_crc[26] ^ calc_crc[27];
    assign crc_bits[3] = calc_crc[25] ^ calc_crc[26] ^ calc_crc[31];
    assign crc_bits[4] = calc_crc[24] ^ calc_crc[25] ^ calc_crc[30] ^ calc_crc[31];
    assign crc_bits[5] = calc_crc[24] ^ calc_crc[30];
    
    assign data_bits[0] = data_xor[0] ^ data_xor[1] ^ data_xor[4] ^ data_xor[5] ^ data_xor[6] ^ data_xor[7];
    assign data_bits[1] = data_xor[0] ^ data_xor[3] ^ data_xor[4] ^ data_xor[6];
    assign data_bits[2] = data_xor[2] ^ data_xor[3];
    assign data_bits[3] = data_xor[1] ^ data_xor[2] ^ data_xor[7];
    assign data_bits[4] = data_xor[0] ^ data_xor[1] ^ data_xor[6] ^ data_xor[7];
    assign data_bits[5] = data_xor[0] ^ data_xor[6];
    
    always @(*) begin
        case({data_valid, SYNC_MODE})
            2'b00: begin
                next_crc = calc_crc;
                crc_error = 0;
            end
            2'b01: begin
                next_crc = {crc_xor[31:6], 
                           crc_bits[0] ^ data_bits[0],
                           crc_bits[1] ^ data_bits[1],
                           crc_bits[2] ^ data_bits[2],
                           crc_bits[3] ^ data_bits[3],
                           crc_bits[4] ^ data_bits[4],
                           crc_bits[5] ^ data_bits[5]};
                crc_error = (next_crc != 32'h0);
            end
            2'b10: begin
                next_crc = calc_crc;
                crc_error = 0;
            end
            2'b11: begin
                next_crc = {crc_xor[31:6], 
                           crc_bits[0] ^ data_bits[0],
                           crc_bits[1] ^ data_bits[1],
                           crc_bits[2] ^ data_bits[2],
                           crc_bits[3] ^ data_bits[3],
                           crc_bits[4] ^ data_bits[4],
                           crc_bits[5] ^ data_bits[5]};
                crc_error = (next_crc != 32'h0) && data_valid;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calc_crc <= 32'hFFFFFFFF;
        end else if (data_valid && SYNC_MODE) begin
            calc_crc <= next_crc;
        end
    end

endmodule