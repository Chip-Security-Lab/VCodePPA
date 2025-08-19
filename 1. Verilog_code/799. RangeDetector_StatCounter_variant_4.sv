//SystemVerilog
module RangeDetector_StatCounter #(
    parameter WIDTH = 8,
    parameter CNT_WIDTH = 16
)(
    input clk, rst_n, clear,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] min_val,
    input [WIDTH-1:0] max_val,
    output reg [CNT_WIDTH-1:0] valid_count,
    // 添加流水线控制信号
    input data_valid_in,
    output reg data_valid_out
);

// 流水线控制信号
reg data_valid_stage1, data_valid_stage2;

// 流水线阶段1：输入数据寄存
reg [WIDTH-1:0] data_in_stage1;
reg [WIDTH-1:0] min_val_stage1;
reg [WIDTH-1:0] max_val_stage1;
reg clear_stage1;

// 流水线阶段2：范围比较
reg [WIDTH-1:0] data_in_stage2;
reg [WIDTH-1:0] min_val_stage2;
reg [WIDTH-1:0] max_val_stage2;
reg clear_stage2;
reg in_range_stage2;

// 流水线阶段3：计数器更新
reg [CNT_WIDTH-1:0] valid_count_next;

// 阶段1：输入数据寄存
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_in_stage1 <= 0;
        min_val_stage1 <= 0;
        max_val_stage1 <= 0;
        clear_stage1 <= 0;
        data_valid_stage1 <= 0;
    end else begin
        data_in_stage1 <= data_in;
        min_val_stage1 <= min_val;
        max_val_stage1 <= max_val;
        clear_stage1 <= clear;
        data_valid_stage1 <= data_valid_in;
    end
end

// 阶段2：比较运算
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_in_stage2 <= 0;
        min_val_stage2 <= 0;
        max_val_stage2 <= 0;
        clear_stage2 <= 0;
        in_range_stage2 <= 0;
        data_valid_stage2 <= 0;
    end else begin
        data_in_stage2 <= data_in_stage1;
        min_val_stage2 <= min_val_stage1;
        max_val_stage2 <= max_val_stage1;
        clear_stage2 <= clear_stage1;
        in_range_stage2 <= (data_in_stage1 >= min_val_stage1) && (data_in_stage1 <= max_val_stage1);
        data_valid_stage2 <= data_valid_stage1;
    end
end

// 阶段3：计数器更新
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        valid_count <= 0;
        data_valid_out <= 0;
    end else begin
        data_valid_out <= data_valid_stage2;
        
        if(clear_stage2) begin
            valid_count <= 0;
        end else if(in_range_stage2 && data_valid_stage2) begin
            valid_count <= valid_count + 1;
        end
    end
end

endmodule