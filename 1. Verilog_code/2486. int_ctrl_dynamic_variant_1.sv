//SystemVerilog
module int_ctrl_dynamic #(
    parameter N_SRC = 8
)(
    input clk, rst,
    input [N_SRC-1:0] req,
    input [N_SRC*8-1:0] prio_map,
    output reg [2:0] curr_pri
);
    integer i, j;
    reg [2:0] temp_pri;
    reg [2:0] sub_result;
    
    // 定义借位减法器的信号
    reg [3:0] minuend;    // 被减数
    reg [3:0] subtrahend; // 减数
    reg [3:0] difference; // 差
    reg [3:0] borrow;     // 借位信号
    
    // 借位减法器函数
    function [2:0] borrow_subtractor;
        input [2:0] a;    // 被减数
        input [2:0] b;    // 减数
        reg [3:0] borrow_internal;
        reg [3:0] diff_internal;
        begin
            // 初始化借位为0
            borrow_internal = 4'b0000;
            
            // 第0位借位计算
            diff_internal[0] = a[0] ^ b[0] ^ borrow_internal[0];
            borrow_internal[1] = (~a[0] & b[0]) | (~a[0] & borrow_internal[0]) | (b[0] & borrow_internal[0]);
            
            // 第1位借位计算
            diff_internal[1] = a[1] ^ b[1] ^ borrow_internal[1];
            borrow_internal[2] = (~a[1] & b[1]) | (~a[1] & borrow_internal[1]) | (b[1] & borrow_internal[1]);
            
            // 第2位借位计算
            diff_internal[2] = a[2] ^ b[2] ^ borrow_internal[2];
            borrow_internal[3] = (~a[2] & b[2]) | (~a[2] & borrow_internal[2]) | (b[2] & borrow_internal[2]);
            
            borrow_subtractor = diff_internal[2:0];
        end
    endfunction
    
    always @(posedge clk) begin
        if(rst) curr_pri <= 3'b0;
        else begin
            temp_pri = 3'b0;
            for(i = 7; i >= 0; i = i - 1) begin
                // 使用借位减法器实现减法
                sub_result = borrow_subtractor(i[2:0], 3'd0);
                
                for(j = 0; j < N_SRC; j = j + 1) begin
                    if(req[j] & prio_map[sub_result*N_SRC+j]) begin
                        temp_pri = sub_result;
                    end
                end
            end
            curr_pri <= temp_pri;
        end
    end
endmodule