//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module delayed_reset_release(
    input wire clk,
    input wire reset_in,
    input wire [3:0] delay_value,
    output reg reset_out
);
    reg [3:0] counter;
    wire [3:0] next_counter;
    wire borrow;
    
    // 使用二进制补码减法算法实现减法运算
    // 对被减数counter取反并加1，再与减数1相加
    // 实现counter - 1的操作
    wire [3:0] counter_neg = ~counter;
    wire [3:0] counter_comp = counter_neg + 4'b0001; // 补码: 取反加1
    assign {borrow, next_counter} = counter + counter_comp; // 等效于counter - 1
    
    always @(posedge clk) begin
        if (reset_in) begin
            counter <= delay_value;
            reset_out <= 1'b1;
        end else if (|counter) begin // 使用归约操作符检查counter是否为0
            counter <= next_counter;
            reset_out <= 1'b1;
        end else
            reset_out <= 1'b0;
    end
endmodule

`default_nettype wire