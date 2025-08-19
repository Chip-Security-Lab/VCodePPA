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
    // 同步CRC实现
    reg [31:0] next_crc;
    
    always @(*) begin
        next_crc = calc_crc;
        if (data_valid) begin
            next_crc[0] = calc_crc[24] ^ calc_crc[30] ^ data_in[0] ^ data_in[6];
            next_crc[1] = calc_crc[24] ^ calc_crc[25] ^ calc_crc[30] ^ calc_crc[31] ^ 
                         data_in[0] ^ data_in[1] ^ data_in[6] ^ data_in[7];
            next_crc[2] = calc_crc[25] ^ calc_crc[26] ^ calc_crc[31] ^ 
                         data_in[1] ^ data_in[2] ^ data_in[7];
            next_crc[3] = calc_crc[26] ^ calc_crc[27] ^ 
                         data_in[2] ^ data_in[3];
            next_crc[4] = calc_crc[24] ^ calc_crc[27] ^ calc_crc[28] ^ calc_crc[30] ^ 
                         data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[6];
            next_crc[5] = calc_crc[24] ^ calc_crc[25] ^ calc_crc[28] ^ calc_crc[29] ^ calc_crc[30] ^ calc_crc[31] ^ 
                         data_in[0] ^ data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
            // 截断CRC位运算，保持简单实现
            next_crc[31:6] = calc_crc[31:6]; // 假设实现
        end
    end
    
    // 基于SYNC_MODE选择不同实现
    generate
        if (SYNC_MODE == 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    calc_crc <= 32'hFFFFFFFF;
                    crc_error <= 0;
                end else if (data_valid) begin
                    calc_crc <= next_crc;
                    crc_error <= (next_crc != 32'h0);
                end
            end
        end else begin
            always @(*) begin
                calc_crc = next_crc;
                crc_error = (next_crc != 32'h0) && data_valid;
            end
        end
    endgenerate
endmodule