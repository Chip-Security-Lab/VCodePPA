//SystemVerilog
module hamming_xor_tree(
    input [31:0] data,
    output [38:0] encoded
);
    // 使用更优化的奇偶校验位计算方法
    reg [5:0] parity;
    wire [31:0] data_arranged;
    wire [15:0] xor_level1 [4:0];
    wire [7:0] xor_level2 [4:0];
    wire [3:0] xor_level3 [4:0];
    wire [1:0] xor_level4 [4:0];
    
    // 重新排列数据以便更高效地计算校验位
    assign data_arranged = data;
    
    // P0-P4: 使用树形结构计算，减少逻辑深度
    genvar i, j;
    generate
        for (i = 0; i < 5; i = i + 1) begin : parity_calc
            // 为每个校验位选择相应的数据位
            for (j = 0; j < 16; j = j + 1) begin : select_bits
                case (i)
                    0: assign xor_level1[i][j] = (j % 2 == 0) ? data[j*2] : 1'b0;
                    1: assign xor_level1[i][j] = ((j/2) % 2 == 0 && j % 4 >= 2) || (j >= 8 && (j/2) % 2 == 1) ? 
                                                  data[j < 8 ? j+j%4 : j+5] : 1'b0;
                    2: assign xor_level1[i][j] = (j >= 4 && j < 8) || (j >= 12) ? data[j+3] : 1'b0;
                    3: assign xor_level1[i][j] = (j >= 8) ? data[j+7] : 1'b0;
                    4: assign xor_level1[i][j] = (j < 16) ? data[j+15] : 1'b0;
                endcase
            end
            
            // 通过多级XOR树计算奇偶校验
            for (j = 0; j < 8; j = j + 1) begin
                assign xor_level2[i][j] = xor_level1[i][j*2] ^ xor_level1[i][j*2+1];
            end
            
            for (j = 0; j < 4; j = j + 1) begin
                assign xor_level3[i][j] = xor_level2[i][j*2] ^ xor_level2[i][j*2+1];
            end
            
            for (j = 0; j < 2; j = j + 1) begin
                assign xor_level4[i][j] = xor_level3[i][j*2] ^ xor_level3[i][j*2+1];
            end
            
            // 最终校验位
            assign parity[i] = xor_level4[i][0] ^ xor_level4[i][1];
        end
    endgenerate
    
    // P5: 总体奇偶校验位 - 使用级联XOR减少扇出
    wire [15:0] total_xor_level1;
    wire [7:0] total_xor_level2;
    wire [3:0] total_xor_level3;
    wire [1:0] total_xor_level4;
    
    generate
        for (i = 0; i < 16; i = i + 1) begin
            if (i < 5) 
                assign total_xor_level1[i] = parity[i];
            else if (i < 13)
                assign total_xor_level1[i] = data[(i-5)*3];
            else
                assign total_xor_level1[i] = data[24+(i-13)];
        end
    endgenerate
    
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign total_xor_level2[i] = total_xor_level1[i*2] ^ total_xor_level1[i*2+1];
        end
        
        for (i = 0; i < 4; i = i + 1) begin
            assign total_xor_level3[i] = total_xor_level2[i*2] ^ total_xor_level2[i*2+1];
        end
        
        for (i = 0; i < 2; i = i + 1) begin
            assign total_xor_level4[i] = total_xor_level3[i*2] ^ total_xor_level3[i*2+1];
        end
    endgenerate
    
    assign parity[5] = total_xor_level4[0] ^ total_xor_level4[1];
    
    // 组装编码输出 - 保持不变
    assign encoded[0] = parity[0];
    assign encoded[1] = parity[1];
    assign encoded[3] = parity[2];
    assign encoded[7] = parity[3];
    assign encoded[15] = parity[4];
    assign encoded[31] = parity[5];
    
    // 数据位放置 - 使用更高效的位宽赋值
    assign encoded[2] = data[0];
    assign encoded[6:4] = data[3:1];
    assign encoded[14:8] = data[10:4]; 
    assign encoded[30:16] = data[26:11];
    assign encoded[38:32] = data[31:27];
endmodule