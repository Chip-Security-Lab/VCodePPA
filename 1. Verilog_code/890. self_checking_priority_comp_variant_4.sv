//SystemVerilog
`timescale 1ns / 1ps

module self_checking_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_index,
    output reg valid,
    output reg error
);
    reg [$clog2(WIDTH)-1:0] expected_priority;
    reg [WIDTH-1:0] priority_mask;
    wire [WIDTH-1:0] data_in_shifted;
    wire [$clog2(WIDTH)-1:0] leading_one_pos;
    
    // 使用移位和编码器优化优先级检测
    assign data_in_shifted = data_in & ~(data_in - 1);  // 保留最低有效1位
    assign leading_one_pos = $clog2(WIDTH)'(WIDTH - 1 - $countones(data_in_shifted));
    
    // 合并valid和error生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 0;
            error <= 0;
        end else begin
            valid <= |data_in;
            error <= valid && ~data_in[expected_priority];
        end
    end
    
    // 优化优先级计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_priority <= 0;
            priority_mask <= 0;
            priority_index <= 0;
        end else begin
            expected_priority <= leading_one_pos;
            priority_mask <= data_in_shifted;
            priority_index <= leading_one_pos;
        end
    end
    
endmodule