//SystemVerilog
module compact_hamming(
    input i_clk,
    input i_rst,
    input i_en,
    input [3:0] i_data,
    output reg [6:0] o_code
);
    // 第一级流水线寄存器：保存输入数据
    reg [3:0] r_data_stage1;
    
    // 第二级流水线寄存器：计算校验位
    reg [3:0] r_data_stage2;
    reg [2:0] r_parity_stage2;
    
    // 第三级流水线寄存器：中间结果缓冲
    reg [3:0] r_data_stage3;
    reg [2:0] r_parity_stage3;
    
    // 第四级流水线寄存器：校验位优化计算
    reg [3:0] r_data_stage4;
    reg [2:0] r_parity_stage4;
    
    // 第一级流水线：缓存输入数据
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_data_stage1 <= 4'b0;
        end else if (i_en) begin
            r_data_stage1 <= i_data;
        end
    end
    
    // 第二级流水线：开始计算校验位
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_data_stage2 <= 4'b0;
            r_parity_stage2 <= 3'b0;
        end else if (i_en) begin
            r_data_stage2 <= r_data_stage1;
            
            // 拆分校验位计算，第一部分
            r_parity_stage2[0] <= r_data_stage1[1] ^ r_data_stage1[2];  // 部分P1
            r_parity_stage2[1] <= r_data_stage1[0] ^ r_data_stage1[2];  // 部分P2
            r_parity_stage2[2] <= r_data_stage1[0] ^ r_data_stage1[1];  // 部分P3
        end
    end
    
    // 第三级流水线：完成校验位计算
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_data_stage3 <= 4'b0;
            r_parity_stage3 <= 3'b0;
        end else if (i_en) begin
            r_data_stage3 <= r_data_stage2;
            
            // 完成校验位计算
            r_parity_stage3[0] <= r_parity_stage2[0] ^ r_data_stage2[3];  // 完成P1
            r_parity_stage3[1] <= r_parity_stage2[1] ^ r_data_stage2[3];  // 完成P2
            r_parity_stage3[2] <= r_parity_stage2[2] ^ r_data_stage2[3];  // 完成P3
        end
    end
    
    // 第四级流水线：准备组装数据
    always @(posedge i_clk) begin
        if (i_rst) begin
            r_data_stage4 <= 4'b0;
            r_parity_stage4 <= 3'b0;
        end else if (i_en) begin
            r_data_stage4 <= r_data_stage3;
            r_parity_stage4 <= r_parity_stage3;
        end
    end
    
    // 第五级流水线：组装最终的汉明码
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_code <= 7'b0;
        end else if (i_en) begin
            // 组装汉明码
            o_code <= {r_data_stage4[3:1], r_parity_stage4[0], 
                       r_data_stage4[0], r_parity_stage4[1], r_parity_stage4[2]};
        end
    end
endmodule