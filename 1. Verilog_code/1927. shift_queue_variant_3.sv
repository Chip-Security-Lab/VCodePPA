//SystemVerilog
module shift_queue #(parameter DW=8, DEPTH=4) (
    input clk,
    input load,
    input shift,
    input [DW*DEPTH-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] queue [0:DEPTH-1];
    integer idx;

    // 条件求和减法算法实现8位减法
    function [DW-1:0] conditional_sum_subtractor;
        input [DW-1:0] a;
        input [DW-1:0] b;
        reg [DW-1:0] sum_0, sum_1;
        reg carry_0, carry_1;
        reg [DW-1:0] temp_b;
        reg [DW:0] carry;
        integer i;
        begin
            temp_b = ~b; // 取反
            carry[0] = 1'b1; // 补码加1
            for (i = 0; i < DW; i = i + 1) begin
                sum_0[i] = a[i] ^ temp_b[i] ^ carry[i];
                carry[i+1] = (a[i] & temp_b[i]) | (a[i] & carry[i]) | (temp_b[i] & carry[i]);
            end
            conditional_sum_subtractor = sum_0;
        end
    endfunction

    always @(posedge clk) begin
        if (load) begin
            for (idx = 0; idx < DEPTH; idx = idx + 1) begin
                queue[idx] <= data_in[idx*DW +: DW];
            end
        end else if (shift) begin
            data_out <= queue[DEPTH-1];
            for (idx = DEPTH-1; idx > 0; idx = idx - 1) begin
                // 使用条件求和减法算法实现减法
                queue[idx] <= conditional_sum_subtractor(queue[idx-1] + queue[idx], queue[idx-1]);
            end
            queue[0] <= {DW{1'b0}};
        end
    end
endmodule