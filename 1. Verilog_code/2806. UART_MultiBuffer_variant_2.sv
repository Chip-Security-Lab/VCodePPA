//SystemVerilog
`timescale 1ns/1ps
module UART_MultiBuffer #(
    parameter BUFFER_LEVEL = 4
)(
    input wire clk,
    input wire [7:0] rx_data,
    input wire rx_valid,
    output wire [7:0] buffer_occupancy,
    input wire buffer_flush
);

reg [7:0] data_pipe [0:BUFFER_LEVEL-1];
reg [BUFFER_LEVEL-1:0] valid_pipe;
integer i;

// 条件求和减法器实现
function [7:0] cond_sum_sub;
    input [7:0] a;
    input [7:0] b;
    reg [7:0] b_comp;
    reg [7:0] sum;
    reg [7:0] g, p, c;
    integer j;
begin
    b_comp = ~b + 8'b1; // 2's complement
    g = a & b_comp;
    p = a ^ b_comp;
    c[0] = 1'b0;
    for (j = 0; j < 7; j = j + 1) begin
        c[j+1] = (g[j]) | (p[j] & c[j]);
    end
    sum[0] = p[0] ^ c[0];
    sum[1] = p[1] ^ c[1];
    sum[2] = p[2] ^ c[2];
    sum[3] = p[3] ^ c[3];
    sum[4] = p[4] ^ c[4];
    sum[5] = p[5] ^ c[5];
    sum[6] = p[6] ^ c[6];
    sum[7] = p[7] ^ c[7];
    cond_sum_sub = sum;
end
endfunction

// 计算有效位数量（buffer占用），用条件求和减法算法实现
function [7:0] count_ones_cond_sum;
    input [BUFFER_LEVEL-1:0] bits;
    reg [7:0] sum1, sum2, sum3, sum4;
begin
    sum1 = {7'b0, bits[0]};
    sum2 = {7'b0, bits[1]};
    sum3 = {7'b0, bits[2]};
    sum4 = {7'b0, bits[3]};
    count_ones_cond_sum = cond_sum_sub(cond_sum_sub(sum1, ~8'b0 + 1), 
                                       cond_sum_sub(cond_sum_sub(sum2, ~8'b0 + 1), 
                                                    cond_sum_sub(sum3, ~8'b0 + 1) + sum4));
end
endfunction

always @(posedge clk) begin
    if (buffer_flush) begin
        for (i = 0; i < BUFFER_LEVEL; i = i + 1) begin
            data_pipe[i] <= 8'b0;
            valid_pipe[i] <= 1'b0;
        end
    end else begin
        for (i = BUFFER_LEVEL-1; i > 0; i = i - 1) begin
            data_pipe[i] <= data_pipe[i-1];
            valid_pipe[i] <= valid_pipe[i-1];
        end
        data_pipe[0] <= rx_data;
        valid_pipe[0] <= rx_valid;
    end
end

assign buffer_occupancy = count_ones_cond_sum(valid_pipe);

endmodule