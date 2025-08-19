//SystemVerilog
module cam_10 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [15:0] wide_data_in,
    output reg wide_match,
    output reg [15:0] wide_store_data
);
    // 流水线寄存器和中间信号
    reg [15:0] data_in_stage1;
    reg write_en_stage1;
    reg [15:0] wide_store_data_next;
    reg compare_valid_stage1;
    reg compare_result_stage1;
    
    // 流水线第一级 - 寄存输入和控制信号
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_stage1 <= 16'b0;
            write_en_stage1 <= 1'b0;
            compare_valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= wide_data_in;
            write_en_stage1 <= write_en;
            compare_valid_stage1 <= ~write_en; // 只有不在写入时才进行比较
        end
    end
    
    // 数据存储和比较逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wide_store_data <= 16'b0;
        end else if (write_en_stage1) begin
            wide_store_data <= data_in_stage1;
        end
    end
    
    // 流水线第二级 - 比较操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            compare_result_stage1 <= 1'b0;
        end else begin
            compare_result_stage1 <= (data_in_stage1 == wide_store_data);
        end
    end
    
    // 流水线第三级 - 输出结果
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wide_match <= 1'b0;
        end else begin
            wide_match <= compare_valid_stage1 & compare_result_stage1;
        end
    end
endmodule