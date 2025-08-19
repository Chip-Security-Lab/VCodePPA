//SystemVerilog
module eth_crc_gen (
    input  wire        clk,
    input  wire        crc_init,
    input  wire        crc_en,
    input  wire [7:0]  data_in,
    output wire [31:0] crc_out
);
    // 阶段1: CRC计算寄存器
    reg  [31:0] crc_reg;
    wire [31:0] next_crc;
    
    // 阶段2: 字节处理流水线
    reg  [31:0] crc_stage1;
    reg         byte_processed;
    
    // 阶段3: 输出翻转流水线
    reg  [31:0] crc_bitswap;
    
    // ==== 阶段1: CRC计算核心逻辑 ====
    // 字节级CRC更新逻辑 - 计算下一个CRC值
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: crc_gen_loop
            assign next_crc[i] = crc_reg[24+i] ^ data_in[i] ^ crc_reg[31];
        end
    endgenerate
    
    // 保持较高位的移位关系
    assign next_crc[31:8] = crc_reg[23:0];
    
    // CRC寄存器更新
    always @(posedge clk) begin
        if (crc_init) begin
            crc_reg <= 32'hFFFFFFFF;
            byte_processed <= 1'b0;
        end 
        else if (crc_en) begin
            crc_reg <= next_crc;
            byte_processed <= 1'b1;
        end
        else begin
            byte_processed <= 1'b0;
        end
    end
    
    // ==== 阶段2: 字节处理完成标记 ====
    always @(posedge clk) begin
        if (crc_init) begin
            crc_stage1 <= 32'hFFFFFFFF;
        end
        else if (byte_processed) begin
            crc_stage1 <= crc_reg;
        end
    end
    
    // ==== 阶段3: 位顺序翻转流水线 ====
    // CRC位顺序重组为以太网标准格式
    always @(posedge clk) begin
        // 按字节重排列，并在每个字节内翻转位顺序
        crc_bitswap <= {
            crc_stage1[24], crc_stage1[25], crc_stage1[26], crc_stage1[27],
            crc_stage1[28], crc_stage1[29], crc_stage1[30], crc_stage1[31],
            crc_stage1[16], crc_stage1[17], crc_stage1[18], crc_stage1[19],
            crc_stage1[20], crc_stage1[21], crc_stage1[22], crc_stage1[23],
            crc_stage1[8],  crc_stage1[9],  crc_stage1[10], crc_stage1[11],
            crc_stage1[12], crc_stage1[13], crc_stage1[14], crc_stage1[15],
            crc_stage1[0],  crc_stage1[1],  crc_stage1[2],  crc_stage1[3],
            crc_stage1[4],  crc_stage1[5],  crc_stage1[6],  crc_stage1[7]
        };
    end
    
    // 最终CRC输出 - 按照以太网规范取反
    assign crc_out = ~crc_bitswap;

endmodule