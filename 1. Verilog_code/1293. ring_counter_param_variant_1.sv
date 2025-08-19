//SystemVerilog
module ring_counter_param #(parameter WIDTH=4) (
    input clk, rst,
    output reg [WIDTH-1:0] counter_reg
);
    // 增加流水线寄存器
    reg [WIDTH-1:0] counter_stage1;
    reg [WIDTH-1:0] counter_stage2;
    
    // 流水线第一级 - 处理复位逻辑
    reg [WIDTH-1:0] reset_value;
    always @(posedge clk) begin
        if (rst)
            reset_value <= {{WIDTH-1{1'b0}}, 1'b1}; // 复位时准备初始值 (0...01)
        else
            reset_value <= {counter_reg[0], counter_reg[WIDTH-1:1]}; // 准备下一个循环移位值
    end
    
    // 流水线第二级 - 中间处理阶段
    always @(posedge clk) begin
        counter_stage1 <= reset_value; // 从第一级获取数据
    end
    
    // 流水线第三级 - 又一个中间处理阶段
    always @(posedge clk) begin
        counter_stage2 <= counter_stage1; // 从第二级获取数据
    end
    
    // 流水线最终级 - 更新输出寄存器
    always @(posedge clk) begin
        counter_reg <= counter_stage2; // 输出最终结果
    end
endmodule