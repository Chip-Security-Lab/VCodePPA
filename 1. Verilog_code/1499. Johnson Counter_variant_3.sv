//SystemVerilog
/****************************************
 * IEEE 1364-2005 Verilog标准
 * 模块名: johnson_counter_pipelined
 * 功能: 4位Johnson计数器流水线版本
 ****************************************/
module johnson_counter_pipelined (
    input wire clk,          // 时钟信号
    input wire arst,         // 异步复位信号
    input wire enable,       // 使能信号
    output wire [3:0] count_out, // 计数器输出
    output wire valid_out    // 输出有效信号
);
    // 内部寄存器声明 - 流水线阶段
    reg [3:0] count_stage1;
    reg [3:0] count_stage2;
    reg [3:0] count_stage3;
    
    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // 第一级流水线：计算下一个Johnson计数值
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            count_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            count_stage1 <= {count_out[2:0], ~count_out[3]};
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线：中间处理阶段
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            count_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else begin
            count_stage2 <= count_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线：最终处理阶段
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            count_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end
        else begin
            count_stage3 <= count_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign count_out = count_stage3;
    assign valid_out = valid_stage3;
    
endmodule