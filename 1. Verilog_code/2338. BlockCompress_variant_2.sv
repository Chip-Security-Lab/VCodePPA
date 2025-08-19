//SystemVerilog
module BlockCompress #(
    parameter BLK = 4
) (
    input                 clk,
    input                 blk_en,
    input  [BLK*8-1:0]    data,
    output reg [15:0]     code
);

    // 使用阶段性异或压缩实现，改善关键路径
    reg [7:0] stage1 [0:BLK-1];
    reg [7:0] stage1_buf1 [0:BLK-1];
    reg [7:0] stage1_buf2 [0:BLK-1];
    reg [15:0] stage2;
    
    // 将循环变量改为寄存器并加入缓冲
    reg [2:0] i_phase1, i_phase2;
    reg [2:0] i_buf1, i_buf2;

    always @(posedge clk) begin
        if (blk_en) begin
            // 第一阶段：将输入数据分为BLK个8位宽的块进行异或压缩
            for (i_phase1 = 0; i_phase1 < BLK; i_phase1 = i_phase1 + 1) begin
                stage1[i_phase1] <= ^data[i_phase1*8 +: 8];
            end
            
            // 为高扇出信号stage1添加缓冲
            for (i_buf1 = 0; i_buf1 < BLK; i_buf1 = i_buf1 + 1) begin
                stage1_buf1[i_buf1] <= stage1[i_buf1];
                stage1_buf2[i_buf1] <= stage1_buf1[i_buf1];
            end
            
            // 为循环变量i添加缓冲
            i_buf1 <= i_phase1;
            i_buf2 <= i_buf1;
            
            // 第二阶段：将压缩结果合并到最终码字
            stage2 <= {8'b0, stage1_buf1[0]};
            for (i_phase2 = 1; i_phase2 < BLK; i_phase2 = i_phase2 + 1) begin
                stage2 <= stage2 ^ {8'b0, stage1_buf2[i_phase2]};
            end
            
            // 最终输出
            code <= stage2;
        end
    end

endmodule