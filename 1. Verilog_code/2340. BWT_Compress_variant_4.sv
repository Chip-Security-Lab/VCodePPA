//SystemVerilog - IEEE 1364-2005
module BWT_Compress #(parameter BLK=8) (
    input wire clk, 
    input wire en,
    input wire [BLK*8-1:0] data_in,
    output reg [BLK*8-1:0] data_out
);

// 内部信号和寄存器定义
wire [7:0] buffer_comb [0:BLK-1];  // 组合逻辑缓冲区
reg [7:0] buffer [0:BLK-1];        // 缓冲区寄存器
reg [7:0] sorted [0:BLK-1];        // 排序数组
reg [3:0] sort_stage;              // 排序阶段控制
reg [3:0] i_reg, j_reg;            // 循环变量寄存器
reg sort_complete;                 // 排序完成标志
reg data_loaded;                   // 数据加载标志

// 移动寄存器到组合逻辑之后 - 数据提取和加载
// 将data_in到buffer的寄存器前移，减少输入到第一级寄存器的延迟
// 组合逻辑部分 - 直接从输入中提取数据
genvar g;
generate
    for (g = 0; g < BLK; g = g + 1) begin : data_extract
        assign buffer_comb[g] = data_in[g*8 +: 8];
    end
endgenerate

// 寄存器部分 - 现在移到组合逻辑之后
always @(posedge clk) begin
    if (en && !data_loaded) begin
        for (integer i = 0; i < BLK; i = i + 1)
            buffer[i] <= buffer_comb[i];
        data_loaded <= 1'b1;
    end else if (!en) begin
        data_loaded <= 1'b0;
    end
end

// 数据初始化模块 - 将buffer复制到排序数组
always @(posedge clk) begin
    if (en && data_loaded && sort_stage == 4'd0) begin
        for (integer i = 0; i < BLK; i = i + 1)
            sorted[i] <= buffer[i];
        sort_stage <= 4'd1;
        i_reg <= 4'd0;
        j_reg <= 4'd0;
        sort_complete <= 1'b0;
    end else if (!en) begin
        sort_stage <= 4'd0;
        sort_complete <= 1'b0;
    end
end

// 冒泡排序控制模块
// 前向流水线处理 - 将比较结果向前寄存
wire compare_result = (sorted[j_reg] > sorted[j_reg+1]);
reg should_swap;

always @(posedge clk) begin
    if (en && data_loaded && sort_stage == 4'd1 && !sort_complete) begin
        should_swap <= compare_result;  // 将比较结果寄存
        
        if (i_reg < BLK-1) begin
            if (j_reg < BLK-1-i_reg) begin
                if (compare_result) begin
                    // 交换操作在下一个模块中完成
                    sort_stage <= 4'd2;
                end else begin
                    j_reg <= j_reg + 4'd1;
                end
            end else begin
                j_reg <= 4'd0;
                i_reg <= i_reg + 4'd1;
            end
        end else begin
            sort_complete <= 1'b1;
            sort_stage <= 4'd3;
        end
    end
end

// 排序交换模块 - 使用前一个时钟周期中寄存的比较结果
always @(posedge clk) begin
    if (en && data_loaded && sort_stage == 4'd2) begin
        if (should_swap) begin  // 使用寄存的比较结果
            sorted[j_reg] <= sorted[j_reg+1];
            sorted[j_reg+1] <= sorted[j_reg];
        end
        sort_stage <= 4'd1;
        j_reg <= j_reg + 4'd1;
    end
end

// 输出组装模块
// 组合逻辑部分 - 预先计算输出数据
wire [BLK*8-1:0] data_out_comb;
assign data_out_comb[7:0] = sorted[BLK-1];
generate
    for (g = 1; g < BLK; g = g + 1) begin : output_gen
        assign data_out_comb[g*8 +: 8] = sorted[g-1];
    end
endgenerate

// 寄存器部分 - 移到组合逻辑之后
always @(posedge clk) begin
    if (en && data_loaded && sort_complete && sort_stage == 4'd3) begin
        data_out <= data_out_comb;
        sort_stage <= 4'd4;
    end
end

endmodule