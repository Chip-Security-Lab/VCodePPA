//SystemVerilog
module test_mode_xnor (
    input wire clk,          // 新增时钟输入用于流水线寄存器
    input wire rst_n,        // 新增复位信号
    input wire test_mode,
    input wire a,
    input wire b,
    output reg y
);

    // 流水线阶段1: 输入寄存
    reg a_reg, b_reg, test_mode_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            test_mode_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            test_mode_reg <= test_mode;
        end
    end
    
    // 流水线阶段2: XOR计算
    reg xor_result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result <= 1'b0;
        end else begin
            xor_result <= a_reg ^ b_reg;
        end
    end
    
    // 流水线阶段3: 结果生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= test_mode_reg ? ~xor_result : 1'b0;
        end
    end
    
endmodule