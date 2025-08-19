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
    // 新增接口，用于流水线控制
    input data_valid,
    output reg ready
);
    // 流水线阶段1：比较逻辑与寄存器
    reg [WIDTH-1:0] data_stage1, min_val_stage1, max_val_stage1;
    reg data_valid_stage1;
    reg clear_stage1;
    
    // 流水线阶段2：计数逻辑相关寄存器
    reg in_range_stage2;
    reg data_valid_stage2;
    reg clear_stage2;
    
    // 流水线控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ready <= 1'b1;
        end else begin
            ready <= 1'b1; // 此设计始终准备好接收新数据
        end
    end
    
    // 流水线阶段1：捕获输入并执行比较
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_stage1 <= 0;
            min_val_stage1 <= 0;
            max_val_stage1 <= 0;
            data_valid_stage1 <= 1'b0;
            clear_stage1 <= 1'b0;
        end else begin
            if(data_valid && ready) begin
                data_stage1 <= data_in;
                min_val_stage1 <= min_val;
                max_val_stage1 <= max_val;
                data_valid_stage1 <= data_valid;
                clear_stage1 <= clear;
            end else if(!data_valid_stage2) begin
                // 当阶段2无有效数据时，可以清除阶段1的有效标志
                data_valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 流水线阶段2：范围检测结果传递
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            in_range_stage2 <= 1'b0;
            data_valid_stage2 <= 1'b0;
            clear_stage2 <= 1'b0;
        end else begin
            if(data_valid_stage1) begin
                in_range_stage2 <= (data_stage1 >= min_val_stage1) && (data_stage1 <= max_val_stage1);
                data_valid_stage2 <= data_valid_stage1;
                clear_stage2 <= clear_stage1;
            end else begin
                data_valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 计数器逻辑 - 最后阶段
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_count <= 0;
        end else if(clear_stage2) begin
            valid_count <= 0;
        end else if(data_valid_stage2 && in_range_stage2) begin
            valid_count <= valid_count + 1;
        end
    end
endmodule