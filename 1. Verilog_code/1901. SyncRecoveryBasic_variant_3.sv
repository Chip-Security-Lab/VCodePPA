//SystemVerilog
module SyncRecoveryBasic #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] noisy_in,
    output reg [WIDTH-1:0] clean_out
);
    // 内部信号声明
    reg [WIDTH-1:0] noisy_in_stage1;
    reg [WIDTH-1:0] inverted_in_stage1;
    reg [WIDTH-1:0] adder_result_stage2;
    reg carry_stage2;
    reg [WIDTH-1:0] noisy_in_stage2;
    reg en_stage1, en_stage2;
    
    // 第1级流水线：寄存输入和准备求补码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            noisy_in_stage1 <= 0;
            inverted_in_stage1 <= 0;
            en_stage1 <= 0;
        end
        else begin
            noisy_in_stage1 <= noisy_in;
            inverted_in_stage1 <= ~noisy_in;
            en_stage1 <= en;
        end
    end
    
    // 第2级流水线：完成补码计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adder_result_stage2 <= 0;
            carry_stage2 <= 0;
            noisy_in_stage2 <= 0;
            en_stage2 <= 0;
        end
        else begin
            {carry_stage2, adder_result_stage2} <= inverted_in_stage1 + 1'b1;
            noisy_in_stage2 <= noisy_in_stage1;
            en_stage2 <= en_stage1;
        end
    end
    
    // 第3级流水线：执行条件求和
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_out <= 0;
        end
        else if (en_stage2) begin
            // 使用条件求和算法计算减法结果
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (noisy_in_stage2[i] == 1'b1) begin
                    clean_out[i] <= 1'b1;
                end
                else begin
                    clean_out[i] <= adder_result_stage2[i];
                end
            end
        end
    end
endmodule