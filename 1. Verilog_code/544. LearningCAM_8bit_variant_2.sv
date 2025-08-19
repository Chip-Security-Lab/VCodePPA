//SystemVerilog
module cam_4 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] write_data,
    input wire [7:0] read_data,
    input wire valid_in,         // 输入有效信号
    output wire valid_out,       // 输出有效信号
    output wire match_flag
);
    // 数据存储寄存器
    reg [7:0] data_a, data_b;
    
    // 第一级流水线寄存器 - 存储输入数据
    reg [7:0] read_data_stage1;
    reg valid_stage1;
    
    // 预计算比较结果的部分比特
    reg [3:0] data_a_high, data_a_low;
    reg [3:0] data_b_high, data_b_low;
    reg [3:0] read_data_high_stage1, read_data_low_stage1;

    // 第二级流水线寄存器 - 比较结果
    reg match_a_high_stage2, match_a_low_stage2;
    reg match_b_high_stage2, match_b_low_stage2;
    reg valid_stage2;

    // 第三级流水线寄存器 - 最终结果
    reg match_a_stage3, match_b_stage3;
    reg valid_stage3;
    
    // 输出级寄存器
    reg match_result_stage4;
    reg valid_stage4;
    
    // 数据存储 - 预处理数据，拆分为高低位
    always @(posedge clk) begin
        if (rst) begin
            data_a <= 8'b0;
            data_b <= 8'b0;
            data_a_high <= 4'b0;
            data_a_low <= 4'b0;
            data_b_high <= 4'b0;
            data_b_low <= 4'b0;
        end else if (write_en) begin
            data_a <= write_data;
            data_b <= write_data;
            data_a_high <= write_data[7:4];
            data_a_low <= write_data[3:0];
            data_b_high <= write_data[7:4];
            data_b_low <= write_data[3:0];
        end
    end
    
    // 第一级流水线 - 注册输入数据并拆分
    always @(posedge clk) begin
        if (rst) begin
            read_data_stage1 <= 8'b0;
            read_data_high_stage1 <= 4'b0;
            read_data_low_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            read_data_stage1 <= read_data;
            read_data_high_stage1 <= read_data[7:4];
            read_data_low_stage1 <= read_data[3:0];
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 拆分比较逻辑，减少关键路径长度
    always @(posedge clk) begin
        if (rst) begin
            match_a_high_stage2 <= 1'b0;
            match_a_low_stage2 <= 1'b0;
            match_b_high_stage2 <= 1'b0;
            match_b_low_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            match_a_high_stage2 <= (data_a_high == read_data_high_stage1);
            match_a_low_stage2 <= (data_a_low == read_data_low_stage1);
            match_b_high_stage2 <= (data_b_high == read_data_high_stage1);
            match_b_low_stage2 <= (data_b_low == read_data_low_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 完成单元匹配逻辑
    always @(posedge clk) begin
        if (rst) begin
            match_a_stage3 <= 1'b0;
            match_b_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            match_a_stage3 <= match_a_high_stage2 && match_a_low_stage2;
            match_b_stage3 <= match_b_high_stage2 && match_b_low_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 第四级流水线 - 结合最终结果
    always @(posedge clk) begin
        if (rst) begin
            match_result_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            match_result_stage4 <= match_a_stage3 || match_b_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 输出赋值
    assign match_flag = match_result_stage4;
    assign valid_out = valid_stage4;
    
endmodule