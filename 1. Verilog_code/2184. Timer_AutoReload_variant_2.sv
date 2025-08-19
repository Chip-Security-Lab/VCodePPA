//SystemVerilog
//IEEE 1364-2005 Verilog
module Timer_AutoReload #(parameter VAL=255) (
    input clk, en, rst,
    output reg alarm
);
    // 流水线寄存器 - 第一级
    reg [7:0] cnt_stage1;
    reg cnt_is_zero_stage1;
    reg valid_stage1;
    
    // 流水线寄存器 - 第二级
    reg [7:0] cnt_stage2;
    reg cnt_is_zero_stage2;
    reg valid_stage2;
    
    // 提前计算零检测以减少关键路径延迟
    wire is_zero = (cnt_stage2 == 8'd0);
    
    // 第一级流水线 - 计算部分
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage1 <= VAL;
            cnt_is_zero_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (en) begin
            cnt_is_zero_stage1 <= is_zero;
            cnt_stage1 <= is_zero ? VAL : (cnt_stage2 - 8'd1);
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线 - 寄存器传递和输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage2 <= VAL;
            cnt_is_zero_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            alarm <= 1'b0;
        end else begin
            // 数据传递
            cnt_stage2 <= cnt_stage1;
            cnt_is_zero_stage2 <= cnt_is_zero_stage1;
            valid_stage2 <= valid_stage1;
            
            // 输出生成
            alarm <= valid_stage2 ? cnt_is_zero_stage2 : alarm;
        end
    end
endmodule