//SystemVerilog
module eth_crc_gen (
    input wire [7:0] data_in,
    input wire crc_en,
    input wire crc_init,
    input wire clk,
    output wire [31:0] crc_out
);
    // 寄存器信号声明
    reg [31:0] crc_reg;
    reg [31:0] crc_out_reg;  // 输出流水线寄存器
    
    // 组合逻辑信号声明
    wire [31:0] next_crc;
    wire [31:0] crc_reversed;
    
    // =====================
    // 组合逻辑部分
    // =====================
    
    // CRC位生成的组合逻辑
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: crc_gen_loop
            assign next_crc[i] = crc_reg[24+i] ^ data_in[i] ^ crc_reg[31];
        end
    endgenerate
    
    // 剩余CRC位的组合逻辑
    assign next_crc[31:8] = crc_reg[23:0];
    
    // 位反转组合逻辑
    assign crc_reversed = {
        crc_reg[24], crc_reg[25], crc_reg[26], crc_reg[27],
        crc_reg[28], crc_reg[29], crc_reg[30], crc_reg[31],
        crc_reg[16], crc_reg[17], crc_reg[18], crc_reg[19],
        crc_reg[20], crc_reg[21], crc_reg[22], crc_reg[23],
        crc_reg[8], crc_reg[9], crc_reg[10], crc_reg[11],
        crc_reg[12], crc_reg[13], crc_reg[14], crc_reg[15],
        crc_reg[0], crc_reg[1], crc_reg[2], crc_reg[3],
        crc_reg[4], crc_reg[5], crc_reg[6], crc_reg[7]
    };
    
    // =====================
    // 时序逻辑部分
    // =====================
    
    // 第一级流水线 - CRC计算与更新
    always @(posedge clk) begin
        if (crc_init)
            crc_reg <= 32'hFFFFFFFF;
        else if (crc_en)
            crc_reg <= next_crc;
    end
    
    // 第二级流水线 - 位反转和取反操作的寄存
    always @(posedge clk) begin
        crc_out_reg <= ~crc_reversed;
    end
    
    // 输出赋值
    assign crc_out = crc_out_reg;
    
endmodule