//SystemVerilog
module BlockCompress #(
    parameter BLK = 4
)(
    input wire clk,
    input wire blk_en,
    input wire [BLK*8-1:0] data,
    output reg [15:0] code
);

    // 先对输入数据进行寄存，减少输入到第一级寄存器的延迟
    reg [BLK*8-1:0] data_reg;
    reg blk_en_reg;
    
    always @(posedge clk) begin
        data_reg <= data;
        blk_en_reg <= blk_en;
    end
    
    // 将异或操作进行流水线处理，减少关键路径延迟
    // 第一级流水线 - 处理前半部分数据
    reg [15:0] xor_stage1;
    reg blk_en_stage1;
    
    always @(posedge clk) begin
        xor_stage1 <= {8'b0, data_reg[7:0]} ^ {8'b0, data_reg[15:8]};
        blk_en_stage1 <= blk_en_reg;
    end
    
    // 第二级流水线 - 处理后半部分数据
    reg [15:0] xor_stage2;
    reg blk_en_stage2;
    
    always @(posedge clk) begin
        xor_stage2 <= {8'b0, data_reg[23:16]} ^ {8'b0, data_reg[31:24]};
        blk_en_stage2 <= blk_en_stage1;
    end
    
    // 第三级流水线 - 合并前后部分结果
    always @(posedge clk) begin
        if (blk_en_stage2) begin
            code <= xor_stage1 ^ xor_stage2;
        end
    end

endmodule