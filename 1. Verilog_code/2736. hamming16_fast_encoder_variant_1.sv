//SystemVerilog
module hamming16_fast_encoder(
    input [15:0] raw_data,
    output [21:0] encoded_data
);
    reg [4:0] parity;
    
    // 计算P0奇偶位
    always @(*) begin
        parity[0] = raw_data[0] ^ raw_data[2] ^ raw_data[4] ^ raw_data[6] ^ 
                   raw_data[8] ^ raw_data[10] ^ raw_data[12] ^ raw_data[14];
    end
    
    // 计算P1奇偶位
    always @(*) begin
        parity[1] = raw_data[1] ^ raw_data[2] ^ raw_data[5] ^ raw_data[6] ^ 
                   raw_data[9] ^ raw_data[10] ^ raw_data[13] ^ raw_data[14];
    end
    
    // 计算P2奇偶位
    always @(*) begin
        parity[2] = raw_data[3] ^ raw_data[4] ^ raw_data[5] ^ raw_data[6] ^ 
                   raw_data[11] ^ raw_data[12] ^ raw_data[13] ^ raw_data[14];
    end
    
    // 计算P3奇偶位
    always @(*) begin
        parity[3] = raw_data[7] ^ raw_data[8] ^ raw_data[9] ^ raw_data[10] ^ 
                   raw_data[11] ^ raw_data[12] ^ raw_data[13] ^ raw_data[14];
    end
    
    // 计算P4总体奇偶位
    always @(*) begin
        reg [3:0] temp1, temp2, temp3, temp4;
        temp1 = raw_data[0] ^ raw_data[1] ^ raw_data[2] ^ raw_data[3];
        temp2 = raw_data[4] ^ raw_data[5] ^ raw_data[6] ^ raw_data[7];
        temp3 = raw_data[8] ^ raw_data[9] ^ raw_data[10] ^ raw_data[11];
        temp4 = raw_data[12] ^ raw_data[13] ^ raw_data[14] ^ raw_data[15];
        parity[4] = temp1 ^ temp2 ^ temp3 ^ temp4 ^ 
                   parity[0] ^ parity[1] ^ parity[2] ^ parity[3];
    end
    
    // 数据重组
    assign encoded_data = {raw_data[15:11], parity[3], 
                          raw_data[10:4], parity[2],
                          raw_data[3:1], parity[1],
                          raw_data[0], parity[0], parity[4]};
endmodule