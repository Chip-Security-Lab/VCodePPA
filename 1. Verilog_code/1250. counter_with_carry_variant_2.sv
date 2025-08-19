//SystemVerilog
module counter_with_carry (
    input wire clk, rst_n,
    input wire enable,  // 添加使能信号控制流水线
    output reg [3:0] count,
    output reg cout
);
    // 组合逻辑生成下一个计数值
    wire [3:0] next_count = count + 1'b1;
    wire next_cout = (next_count == 4'b1111);
    
    // 流水线阶段1: 寄存前移到组合逻辑后
    reg [3:0] count_stage1;
    reg cout_stage1;
    reg valid_stage1;
    
    // 流水线阶段2: 计算进位
    reg [3:0] count_stage2;
    reg cout_stage2;
    reg valid_stage2;
    
    // 阶段1: 前向寄存器重定时，移动到组合逻辑之后
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage1 <= 4'b0000;
            cout_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            count_stage1 <= next_count;
            cout_stage1 <= next_cout;
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 阶段2: 根据阶段1的数据传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage2 <= 4'b0000;
            cout_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            count_stage2 <= count_stage1;
            cout_stage2 <= cout_stage1;
            valid_stage2 <= 1'b1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 输出阶段: 更新最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'b0000;
            cout <= 1'b0;
        end
        else if (valid_stage2) begin
            count <= count_stage2;
            cout <= cout_stage2;
        end
    end
endmodule