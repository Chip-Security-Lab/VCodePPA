//SystemVerilog
module compact_hamming(
    input i_clk, 
    input i_rst, 
    input i_en,
    input [3:0] i_data,
    output reg [6:0] o_code,
    output reg o_valid
);
    // 第一级流水线寄存器和控制信号
    reg [3:0] data_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器和中间结果
    reg [3:0] data_stage2;
    reg valid_stage2;
    reg p1_stage2; // 奇偶校验位1
    
    // 第三级流水线寄存器和中间结果
    reg [3:0] data_stage3;
    reg valid_stage3;
    reg p1_stage3;
    reg p2_stage3; // 奇偶校验位2
    
    // 第一级流水线：寄存输入数据
    always @(posedge i_clk) begin
        if (i_rst) begin
            data_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else if (i_en) begin
            data_stage1 <= i_data;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线：计算第一个校验位
    always @(posedge i_clk) begin
        if (i_rst) begin
            data_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
            p1_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            data_stage2 <= data_stage1;
            p1_stage2 <= ^{data_stage1[1], data_stage1[2], data_stage1[3]};
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 第三级流水线：计算第二个校验位
    always @(posedge i_clk) begin
        if (i_rst) begin
            data_stage3 <= 4'b0;
            valid_stage3 <= 1'b0;
            p1_stage3 <= 1'b0;
            p2_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            data_stage3 <= data_stage2;
            p1_stage3 <= p1_stage2;
            p2_stage3 <= ^{data_stage2[0], data_stage2[2], data_stage2[3]};
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // 最终输出级：计算第三个校验位并组合输出码字
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_code <= 7'b0;
            o_valid <= 1'b0;
        end else if (valid_stage3) begin
            o_code <= {data_stage3[3:1], 
                      p1_stage3, 
                      data_stage3[0], 
                      p2_stage3, 
                      ^{data_stage3[0], data_stage3[1], data_stage3[3]}};
            o_valid <= 1'b1;
        end else begin
            o_valid <= 1'b0;
        end
    end
endmodule