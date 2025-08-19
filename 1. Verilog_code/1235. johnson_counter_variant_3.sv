//SystemVerilog
module johnson_counter (
    input  wire       clk,
    input  wire       rst,
    input  wire       enable,  // 流水线使能信号
    output reg  [3:0] q,
    output reg        valid_out  // 输出有效信号
);
    // 流水线阶段寄存器
    reg [3:0] q_stage1;
    reg [3:0] q_stage2;
    reg valid_stage1, valid_stage2;
    
    // 流水线第一级 - 状态计算
    always @(posedge clk) begin
        if (rst) begin
            q_stage1 <= 4'b0000;
        end else if (enable) begin
            q_stage1 <= {q[2:0], ~q[3]};
        end
    end
    
    // 流水线第一级 - 有效信号控制
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            valid_stage1 <= 1'b1;
        end
    end
    
    // 流水线第二级 - 数据缓冲
    always @(posedge clk) begin
        if (rst) begin
            q_stage2 <= 4'b0000;
        end else if (enable) begin
            q_stage2 <= q_stage1;
        end
    end
    
    // 流水线第二级 - 有效信号缓冲
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
        end else if (enable) begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线第三级 - 输出数据寄存器
    always @(posedge clk) begin
        if (rst) begin
            q <= 4'b0000;
        end else if (enable) begin
            q <= q_stage2;
        end
    end
    
    // 流水线第三级 - 输出有效信号控制
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
        end else if (enable) begin
            valid_out <= valid_stage2;
        end
    end
endmodule