//SystemVerilog
module bidirectional_shifter(
    input wire [31:0] data,
    input wire [4:0] shift_amount,
    input wire direction,  // 0: left, 1: right
    input wire clk,
    input wire rst_n,
    output reg [31:0] result
);

    // 流水线阶段1：输入寄存器和移位准备
    reg [31:0] data_reg;
    reg [4:0] shift_amount_reg;
    reg direction_reg;
    
    // 流水线阶段2：部分移位结果
    reg [31:0] shift_stage1;
    
    // 流水线阶段3：最终移位结果
    reg [31:0] shift_stage2;
    
    // 预计算移位结果，减少关键路径延迟
    wire [31:0] left_shift_result;
    wire [31:0] right_shift_result;
    wire [31:0] shift_result;
    
    // 使用组合逻辑预计算移位结果
    assign left_shift_result = data_reg << shift_amount_reg;
    assign right_shift_result = data_reg >> shift_amount_reg;
    
    // 使用多路选择器选择移位方向，减少条件判断延迟
    assign shift_result = direction_reg ? right_shift_result : left_shift_result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            data_reg <= 32'b0;
            shift_amount_reg <= 5'b0;
            direction_reg <= 1'b0;
            shift_stage1 <= 32'b0;
            shift_stage2 <= 32'b0;
            result <= 32'b0;
        end else begin
            // 流水线阶段1：寄存输入信号
            data_reg <= data;
            shift_amount_reg <= shift_amount;
            direction_reg <= direction;
            
            // 流水线阶段2：使用预计算的移位结果
            shift_stage1 <= shift_result;
            
            // 流水线阶段3：将结果传送到输出
            shift_stage2 <= shift_stage1;
            result <= shift_stage2;
        end
    end
endmodule