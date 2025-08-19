//SystemVerilog
module mux_based_shifter (
    input wire clk,           // 添加时钟信号用于流水线寄存器
    input wire rst_n,         // 添加复位信号
    input wire [7:0] data,    // 输入数据
    input wire [2:0] shift,   // 移位控制信号
    output wire [7:0] result  // 结果
);
    // 第一级移位控制信号和数据寄存器
    reg [7:0] data_reg;
    reg [2:0] shift_reg;
    
    // 第一级移位结果寄存器
    reg [7:0] stage1_result;
    
    // 第二级移位控制和结果寄存器
    reg [1:0] shift_stage2;
    reg [7:0] stage2_result;
    
    // 第三级移位控制和最终结果
    reg shift_stage3;
    reg [7:0] final_result;
    
    // 流水线第一级 - 输入寄存器和第一级移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
            shift_reg <= 3'b0;
            stage1_result <= 8'b0;
        end else begin
            data_reg <= data;
            shift_reg <= shift;
            
            // 执行第一级移位操作 (1位循环移位)
            stage1_result <= shift_reg[0] ? {data_reg[6:0], data_reg[7]} : data_reg;
        end
    end
    
    // 流水线第二级 - 第二级移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_stage2 <= 2'b0;
            stage2_result <= 8'b0;
        end else begin
            shift_stage2 <= shift_reg[2:1];
            
            // 执行第二级移位操作 (2位循环移位)
            stage2_result <= shift_reg[1] ? {stage1_result[5:0], stage1_result[7:6]} : stage1_result;
        end
    end
    
    // 流水线第三级 - 最终移位和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_stage3 <= 1'b0;
            final_result <= 8'b0;
        end else begin
            shift_stage3 <= shift_stage2[1];
            
            // 执行第三级移位操作 (4位循环移位)
            final_result <= shift_stage2[1] ? {stage2_result[3:0], stage2_result[7:4]} : stage2_result;
        end
    end
    
    // 输出赋值
    assign result = final_result;

endmodule