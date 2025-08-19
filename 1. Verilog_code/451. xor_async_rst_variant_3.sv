//SystemVerilog
module xor_async_rst(
    input clk, rst_n,
    input a, b,
    input valid_in,
    output reg valid_out,
    output reg y
);
    // 中间组合逻辑结果
    wire xor_result;
    
    // 计算XOR结果的组合逻辑
    assign xor_result = a ^ b;
    
    // 移动后的流水线寄存
    reg xor_stage1;
    reg valid_stage1;
    
    // 第一级流水线：直接计算XOR结果并寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            xor_stage1 <= xor_result;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 0;
            valid_out <= 0;
        end else begin
            y <= xor_stage1;
            valid_out <= valid_stage1;
        end
    end
endmodule