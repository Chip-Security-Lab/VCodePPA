//SystemVerilog
module registered_crc16(
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    input wire calculate,
    output reg [15:0] crc_reg_out
);
    localparam [15:0] POLY = 16'h8005;
    
    // 增加流水线深度，分成3个阶段
    reg [15:0] crc_temp;
    reg [15:0] crc_xor_stage1;
    reg [15:0] data_in_stage1;
    reg [15:0] crc_next_stage2;
    reg calculate_stage1, calculate_stage2;
    
    // 第一阶段：数据输入和XOR运算
    always @(posedge clk) begin
        if (rst) begin
            crc_temp <= 16'hFFFF;
            crc_xor_stage1 <= 16'h0000;
            data_in_stage1 <= 16'h0000;
            calculate_stage1 <= 1'b0;
        end else begin
            if (calculate) begin
                crc_xor_stage1 <= crc_temp ^ data_in;
                data_in_stage1 <= data_in;
            end
            calculate_stage1 <= calculate;
        end
    end
    
    // 实现CRC位计算的组合逻辑，供第二阶段使用
    wire [15:0] crc_next;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: bit_loop
            if (i == 0) begin
                assign crc_next[i] = crc_xor_stage1[15] ^ crc_xor_stage1[1] ^ crc_xor_stage1[2] ^ 
                                    crc_xor_stage1[4] ^ crc_xor_stage1[6] ^ crc_xor_stage1[8] ^ 
                                    crc_xor_stage1[10] ^ crc_xor_stage1[12] ^ crc_xor_stage1[14];
            end else if (i == 1) begin
                assign crc_next[i] = crc_xor_stage1[15] ^ crc_xor_stage1[0] ^ crc_xor_stage1[2] ^ 
                                    crc_xor_stage1[3] ^ crc_xor_stage1[5] ^ crc_xor_stage1[7] ^ 
                                    crc_xor_stage1[9] ^ crc_xor_stage1[11] ^ crc_xor_stage1[13];
            end else begin
                assign crc_next[i] = crc_xor_stage1[i-2];
            end
        end
    endgenerate
    
    // 第二阶段：CRC计算
    always @(posedge clk) begin
        if (rst) begin
            crc_next_stage2 <= 16'h0000;
            calculate_stage2 <= 1'b0;
        end else begin
            if (calculate_stage1) begin
                crc_next_stage2 <= crc_next;
            end
            calculate_stage2 <= calculate_stage1;
        end
    end
    
    // 第三阶段：更新寄存器和输出
    always @(posedge clk) begin
        if (rst) begin
            crc_reg_out <= 16'h0000;
        end else if (calculate_stage2) begin
            crc_temp <= crc_next_stage2;
            crc_reg_out <= crc_next_stage2;
        end
    end
endmodule