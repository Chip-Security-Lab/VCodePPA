//SystemVerilog
module Cascaded_AND (
    input  wire [2:0] in,
    input  wire       clk,
    input  wire       rst_n,
    output reg        out
);

    // 第一级流水线：缓存输入信号
    reg [2:0] in_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_stage1 <= 3'b000;
        end else begin
            in_stage1 <= in;
        end
    end
    
    // 第二级流水线：计算前两个输入的AND结果
    reg and_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_stage2 <= 1'b0;
        end else begin
            and_stage2 <= in_stage1[0] & in_stage1[1];
        end
    end
    
    // 第三级流水线：缓存第三个输入信号
    reg in2_stage3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in2_stage3 <= 1'b0;
        end else begin
            in2_stage3 <= in_stage1[2];
        end
    end
    
    // 第四级流水线：计算最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 1'b0;
        end else begin
            out <= and_stage2 & in2_stage3;
        end
    end

endmodule