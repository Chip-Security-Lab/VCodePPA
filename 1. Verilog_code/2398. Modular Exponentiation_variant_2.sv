//SystemVerilog
module mod_exp #(parameter WIDTH = 16) (
    input wire clk, reset,
    input wire start,
    input wire [WIDTH-1:0] base, exponent, modulus,
    output reg [WIDTH-1:0] result,
    output reg done
);
    // 状态寄存器和数据寄存器声明
    reg [WIDTH-1:0] exp_reg, base_reg;
    reg calculating;
    reg [WIDTH-1:0] temp_result, temp_base;
    
    // 使用桶形移位器结构实现右移操作
    function [WIDTH-1:0] barrel_shifter_right;
        input [WIDTH-1:0] data;
        input [0:0] shift;
        reg [WIDTH-1:0] temp;
        begin
            // 1位右移层
            temp = shift ? {1'b0, data[WIDTH-1:1]} : data;
            barrel_shifter_right = temp;
        end
    endfunction
    
    // 状态控制逻辑
    always @(posedge clk) begin
        if (reset) begin
            calculating <= 0;
            done <= 0;
        end else if (start) begin
            calculating <= 1;
            done <= 0;
        end else if (calculating && exp_reg == 0) begin
            calculating <= 0;
            done <= 1;
        end
    end
    
    // 指数寄存器逻辑 - 使用桶形移位器
    always @(posedge clk) begin
        if (reset) begin
            exp_reg <= 0;
        end else if (start) begin
            exp_reg <= exponent;
        end else if (calculating && exp_reg != 0) begin
            exp_reg <= barrel_shifter_right(exp_reg, 1'b1);
        end
    end
    
    // 基数寄存器逻辑
    always @(posedge clk) begin
        if (reset) begin
            base_reg <= 0;
        end else if (start) begin
            base_reg <= base;
        end else if (calculating && exp_reg != 0) begin
            temp_base = (base_reg * base_reg) % modulus;
            base_reg <= temp_base;
        end
    end
    
    // 结果计算逻辑
    always @(posedge clk) begin
        if (reset) begin
            result <= 1;
        end else if (start) begin
            result <= 1;
        end else if (calculating && exp_reg != 0 && exp_reg[0]) begin
            temp_result = (result * base_reg) % modulus;
            result <= temp_result;
        end
    end
    
endmodule