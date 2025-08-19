//SystemVerilog
module sync_divider_4bit (
    input clk,
    input reset,
    input [3:0] a,
    input [3:0] b,
    input valid_in,           // 输入数据有效信号
    output ready_in,          // 输入准备好接收新数据
    output reg [3:0] quotient,
    output reg valid_out      // 输出数据有效信号
);
    // 流水线寄存器
    reg [3:0] a_stage1, a_stage2;
    reg [3:0] b_stage1, b_stage2;
    reg valid_stage1, valid_stage2;
    
    // 中间结果
    reg [3:0] quotient_temp;
    
    // 控制信号
    wire stall;
    assign stall = valid_out && !ready_in;  // 当输出有效但下游未准备好时停滞
    assign ready_in = !stall;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_stage1 <= 4'b0;
            b_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end
        else if (!stall) begin
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 除法运算
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_stage2 <= 4'b0;
            b_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
            quotient_temp <= 4'b0;
        end
        else if (!stall) begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            valid_stage2 <= valid_stage1;
            // 防止除以零
            quotient_temp <= (b_stage1 != 0) ? a_stage1 / b_stage1 : 4'b0;
        end
    end
    
    // 第三级流水线 - 输出寄存
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 4'b0;
            valid_out <= 1'b0;
        end
        else if (!stall) begin
            quotient <= quotient_temp;
            valid_out <= valid_stage2;
        end
    end
    
endmodule