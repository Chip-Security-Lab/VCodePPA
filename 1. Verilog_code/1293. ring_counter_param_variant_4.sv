//SystemVerilog
// 顶层模块
module ring_counter_param #(
    parameter WIDTH = 4,
    parameter STAGES = 3  // 流水线级数
)(
    input wire clk,
    input wire rst,
    input wire enable,    // 流水线启动控制信号
    output wire [WIDTH-1:0] counter_reg,
    output wire valid_out  // 输出有效信号
);

    // 内部信号和流水线寄存器
    wire [WIDTH-1:0] next_counter;
    wire [WIDTH-1:0] current_counter;
    
    // 流水线控制信号
    reg [STAGES-1:0] valid_pipeline;
    
    // 子模块实例化
    counter_register #(
        .WIDTH(WIDTH)
    ) register_unit (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .next_value(next_counter),
        .current_value(current_counter)
    );
    
    pipelined_shift_logic #(
        .WIDTH(WIDTH),
        .STAGES(STAGES)
    ) shift_unit (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .valid_in(valid_pipeline[0]),
        .current_value(current_counter),
        .next_value(next_counter),
        .valid_out(valid_out)
    );
    
    // 流水线控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            valid_pipeline <= {STAGES{1'b0}};
        end
        else if (enable) begin
            valid_pipeline <= {valid_pipeline[STAGES-2:0], enable};
        end
    end
    
    // 输出赋值
    assign counter_reg = current_counter;
    
endmodule

// 寄存器子模块（带使能）
module counter_register #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [WIDTH-1:0] next_value,
    output reg [WIDTH-1:0] current_value
);

    always @(posedge clk) begin
        if (rst)
            current_value <= {{WIDTH-1{1'b0}}, 1'b1}; // 复位值：最低位为1，其他位为0
        else if (enable)
            current_value <= next_value;
    end
    
endmodule

// 流水线化移位逻辑子模块
module pipelined_shift_logic #(
    parameter WIDTH = 4,
    parameter STAGES = 3
)(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire valid_in,
    input wire [WIDTH-1:0] current_value,
    output wire [WIDTH-1:0] next_value,
    output wire valid_out
);
    // 流水线寄存器
    reg [WIDTH-1:0] shift_stage1;
    reg [WIDTH-1:0] shift_stage2;
    reg [WIDTH-1:0] shift_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线 - 初始移位
    wire [WIDTH-1:0] shift_result1 = {current_value[WIDTH-2:0], current_value[WIDTH-1]};
    
    // 第二级流水线 - 反转移位
    wire [WIDTH-1:0] shift_result2 = {shift_stage1[0], shift_stage1[WIDTH-1:1]};
    
    // 第三级流水线 - 最终移位
    wire [WIDTH-1:0] shift_result3 = {shift_stage2[0], shift_stage2[WIDTH-1:1]};
    
    // 流水线寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            shift_stage1 <= {WIDTH{1'b0}};
            shift_stage2 <= {WIDTH{1'b0}};
            shift_stage3 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else if (enable) begin
            // 数据流水线
            shift_stage1 <= shift_result1;
            shift_stage2 <= shift_result2;
            shift_stage3 <= shift_result3;
            
            // 控制流水线
            valid_stage1 <= valid_in;
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign next_value = shift_stage3;
    assign valid_out = valid_stage3;
    
endmodule