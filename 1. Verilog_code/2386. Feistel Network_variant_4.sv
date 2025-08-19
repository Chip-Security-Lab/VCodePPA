//SystemVerilog
module feistel_network #(parameter HALF_WIDTH = 16) (
    input wire clk, rst_n, enable,
    input wire [HALF_WIDTH-1:0] left_in, right_in,
    input wire [HALF_WIDTH-1:0] round_key,
    output reg [HALF_WIDTH-1:0] left_out, right_out,
    input wire valid_in,
    output reg valid_out,
    // 新增流水线控制信号
    input wire flush,
    output reg ready_in,
    input wire ready_out
);
    // Stage 1 signals
    reg [HALF_WIDTH-1:0] right_stage1, left_stage1;
    reg [HALF_WIDTH-1:0] round_key_stage1;
    reg valid_stage1;
    
    // Stage 2 signals
    reg [HALF_WIDTH-1:0] f_output_stage2;
    reg [HALF_WIDTH-1:0] right_stage2;
    reg [HALF_WIDTH-1:0] left_stage2;
    reg valid_stage2;
    
    // Stage 3 signals
    reg [HALF_WIDTH-1:0] left_stage3;
    reg [HALF_WIDTH-1:0] f_output_stage3;
    reg valid_stage3;
    
    // 流水线状态控制
    wire stall = valid_out && !ready_out;
    assign ready_in = !stall;
    
    // 增强的F函数 - 将原来的简单异或操作扩展为更复杂的操作
    function [HALF_WIDTH-1:0] f_function(input [HALF_WIDTH-1:0] data, input [HALF_WIDTH-1:0] key);
        reg [HALF_WIDTH-1:0] temp;
        begin
            // 分阶段计算，使其更适合流水线
            temp = data ^ key;
            temp = {temp[HALF_WIDTH-2:0], temp[HALF_WIDTH-1]} ^ key; // 循环左移1位后再异或
            f_function = temp ^ (data >> 1); // 添加右移后异或，增加复杂度
        end
    endfunction
    
    // Pipeline Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            right_stage1 <= 0;
            left_stage1 <= 0;
            round_key_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (flush) begin
            valid_stage1 <= 0;
        end else if (enable && !stall) begin
            right_stage1 <= right_in;
            left_stage1 <= left_in;
            round_key_stage1 <= round_key;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline Stage 2: First part of F function
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            right_stage2 <= 0;
            left_stage2 <= 0;
            f_output_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (flush) begin
            valid_stage2 <= 0;
        end else if (enable && !stall) begin
            // F函数第一部分：数据和密钥异或
            f_output_stage2 <= right_stage1 ^ round_key_stage1;
            right_stage2 <= right_stage1;
            left_stage2 <= left_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline Stage 3: Second part of F function
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_stage3 <= 0;
            f_output_stage3 <= 0;
            valid_stage3 <= 0;
        end else if (flush) begin
            valid_stage3 <= 0;
        end else if (enable && !stall) begin
            // F函数第二部分：循环移位和进一步变换
            f_output_stage3 <= {f_output_stage2[HALF_WIDTH-2:0], f_output_stage2[HALF_WIDTH-1]} ^ right_stage2[HALF_WIDTH-1:1];
            left_stage3 <= left_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline Stage 4: Final computation and outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_out <= 0;
            right_out <= 0;
            valid_out <= 0;
        end else if (flush) begin
            valid_out <= 0;
        end else if (enable && !stall) begin
            left_out <= right_stage2;
            right_out <= left_stage3 ^ f_output_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule