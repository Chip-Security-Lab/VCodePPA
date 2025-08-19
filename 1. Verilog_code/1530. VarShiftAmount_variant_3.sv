//SystemVerilog
// IEEE 1364-2005 Verilog标准
module VarShiftAmount #(parameter MAX_SHIFT=4, WIDTH=8) (
    input clk,
    input rst_n,
    input [MAX_SHIFT-1:0] shift_num,
    input dir, // 0-left 1-right
    input [WIDTH-1:0] din,
    input valid_in,
    output valid_out,
    output [WIDTH-1:0] dout
);

    // 阶段1寄存器 - 存储输入和控制信号
    reg [WIDTH-1:0] din_stage1;
    reg [MAX_SHIFT-1:0] shift_num_stage1;
    reg dir_stage1;
    reg valid_stage1;
    
    // 阶段2寄存器 - 存储移位1的结果
    reg [WIDTH-1:0] shift_stage2;
    reg valid_stage2;
    
    // 阶段3寄存器 - 存储移位2的结果
    reg [WIDTH-1:0] shift_stage3;
    reg valid_stage3;
    
    // 第一阶段 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1 <= {WIDTH{1'b0}};
            shift_num_stage1 <= {MAX_SHIFT{1'b0}};
            dir_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            din_stage1 <= din;
            shift_num_stage1 <= shift_num;
            dir_stage1 <= dir;
            valid_stage1 <= valid_in;
        end
    end
    
    // 阶段2 - 执行第一级移位 (最多移动MAX_SHIFT/2位)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                if (dir_stage1) begin
                    // 右移第一部分
                    if (shift_num_stage1[MAX_SHIFT/2]) 
                        shift_stage2 <= din_stage1 >> (1 << (MAX_SHIFT/2));
                    else
                        shift_stage2 <= din_stage1;
                end
                else begin
                    // 左移第一部分
                    if (shift_num_stage1[MAX_SHIFT/2]) 
                        shift_stage2 <= din_stage1 << (1 << (MAX_SHIFT/2));
                    else
                        shift_stage2 <= din_stage1;
                end
            end
        end
    end
    
    // 阶段3 - 执行第二级移位 (处理剩余的移位量)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end
        else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                if (dir_stage1) begin
                    // 右移第二部分
                    if (shift_num_stage1[MAX_SHIFT/2-1:0] != 0)
                        shift_stage3 <= shift_stage2 >> shift_num_stage1[MAX_SHIFT/2-1:0];
                    else
                        shift_stage3 <= shift_stage2;
                end
                else begin
                    // 左移第二部分
                    if (shift_num_stage1[MAX_SHIFT/2-1:0] != 0)
                        shift_stage3 <= shift_stage2 << shift_num_stage1[MAX_SHIFT/2-1:0];
                    else
                        shift_stage3 <= shift_stage2;
                end
            end
        end
    end
    
    // 输出赋值
    assign dout = shift_stage3;
    assign valid_out = valid_stage3;

endmodule