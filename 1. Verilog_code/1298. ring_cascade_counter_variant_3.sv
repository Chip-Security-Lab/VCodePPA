//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块 - 流水线环形级联计数器
module ring_cascade_counter (
    input wire clk,
    input wire reset,
    output wire [3:0] stages,
    output wire carry_out
);

    // 流水线阶段寄存器
    reg [3:0] counter_value_stage1;
    reg [3:0] counter_value_stage2;
    reg valid_stage1, valid_stage2;
    reg carry_out_stage1;
    
    // 第一级流水线 - 计数器核心 (扁平化if-else结构)
    always @(posedge clk) begin
        if (reset) begin
            counter_value_stage1 <= 4'b1000;
            valid_stage1 <= 1'b0;
        end
        else if (!reset) begin
            counter_value_stage1 <= {counter_value_stage1[0], counter_value_stage1[3:1]};
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线 - 进位检测和结果传递 (扁平化if-else结构)
    always @(posedge clk) begin
        if (reset) begin
            counter_value_stage2 <= 4'b0000;
            carry_out_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (!reset) begin
            counter_value_stage2 <= counter_value_stage1;
            carry_out_stage1 <= (counter_value_stage1 == 4'b0001);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign stages = counter_value_stage2;
    assign carry_out = carry_out_stage1 & valid_stage2;

endmodule