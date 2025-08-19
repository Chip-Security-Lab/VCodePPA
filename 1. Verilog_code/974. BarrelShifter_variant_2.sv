//SystemVerilog
module BarrelShifter #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0] data_in,
    input  wire [3:0]       shift_ctrl,
    output reg  [WIDTH-1:0] data_out
);
    // 流水线阶段1: 移位量准备和数据准备
    reg [3:0]       shift_amount_stage1;
    reg [WIDTH-1:0] data_stage1;
    
    // 流水线阶段2: 条件求和减法移位实现
    reg [WIDTH-1:0] shifted_data_stage2;
    
    // 条件求和减法所需的中间信号
    reg [WIDTH-1:0] shift_result;
    reg [WIDTH-1:0] temp_result;
    reg [3:0] remaining_shift;
    reg carry;
    
    // 主数据流路径 - 阶段1: 寄存输入数据和移位控制
    always @(*) begin
        shift_amount_stage1 = shift_ctrl;
        data_stage1 = data_in;
    end
    
    // 主数据流路径 - 阶段2: 使用条件求和减法算法实现移位
    always @(*) begin
        // 初始化
        shift_result = data_stage1;
        remaining_shift = shift_amount_stage1;
        
        // 条件求和移位实现
        // 1位移位
        if (remaining_shift[0]) begin
            temp_result = {shift_result[WIDTH-2:0], 1'b0};
            shift_result = temp_result;
        end
        
        // 2位移位
        if (remaining_shift[1]) begin
            temp_result = {shift_result[WIDTH-3:0], 2'b00};
            shift_result = temp_result;
        end
        
        // 4位移位
        if (remaining_shift[2]) begin
            temp_result = {shift_result[WIDTH-5:0], 4'b0000};
            shift_result = temp_result;
        end
        
        // 8位移位 (如果WIDTH足够大)
        if (WIDTH > 8 && remaining_shift[3]) begin
            temp_result = {shift_result[WIDTH-9:0], 8'h00};
            shift_result = temp_result;
        end
        else if (remaining_shift[3]) begin
            // 如果WIDTH不足8位，则全部填充为0
            shift_result = {WIDTH{1'b0}};
        end
        
        shifted_data_stage2 = shift_result;
    end
    
    // 输出阶段: 最终数据输出
    always @(*) begin
        data_out = shifted_data_stage2;
    end
endmodule