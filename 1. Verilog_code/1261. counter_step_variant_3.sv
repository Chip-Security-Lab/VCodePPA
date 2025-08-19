//SystemVerilog
module counter_step #(parameter WIDTH=4, STEP=2) (
    input clk, rst_n,
    input en,                     // 启用信号
    output reg valid_out,         // 输出有效信号
    output reg [WIDTH-1:0] cnt
);
    // 内部流水线寄存器
    reg [WIDTH-1:0] cnt_stage1;
    reg valid_stage1;
    
    // 流水线第一级：计算新的计数值
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else if (en) begin
            cnt_stage1 <= cnt + STEP;
            valid_stage1 <= 1'b1;
        end
        else begin
            cnt_stage1 <= cnt_stage1;
            valid_stage1 <= 1'b0;
        end
    end
    
    // 流水线第二级：将结果输出
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt <= 0;
            valid_out <= 0;
        end
        else if (valid_stage1) begin
            cnt <= cnt_stage1;
            valid_out <= valid_stage1;
        end
        else begin
            cnt <= cnt;
            valid_out <= 1'b0;
        end
    end
endmodule