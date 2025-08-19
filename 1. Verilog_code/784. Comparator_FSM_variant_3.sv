//SystemVerilog
module Comparator_FSM #(parameter WIDTH = 16) (
    input              clk,
    input              start,
    input  [WIDTH-1:0] val_m,
    input  [WIDTH-1:0] val_n,
    output reg         done,
    output reg         equal
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam COMPARE = 2'b01;
    localparam DONE = 2'b10;
    
    // 状态寄存器
    reg [1:0] curr_state, next_state;
    
    // 借位减法相关寄存器
    reg [1:0] borrow_chain;
    reg [1:0] subtraction_result;
    
    // 比较结果寄存器
    reg equal_result;
    reg done_signal;
    
    // 初始化
    initial begin
        curr_state = IDLE;
        next_state = IDLE;
        done = 0;
        equal = 0;
        borrow_chain = 0;
        subtraction_result = 0;
        equal_result = 0;
        done_signal = 0;
    end
    
    // 借位减法器函数
    function [2:0] borrow_subtractor;
        input [1:0] a;
        input [1:0] b;
        reg [1:0] result;
        reg borrow_out;
        reg borrow_internal;
        begin
            // 最低位计算
            result[0] = a[0] ^ b[0];
            borrow_internal = (~a[0]) & b[0];
            
            // 最高位计算
            result[1] = a[1] ^ b[1] ^ borrow_internal;
            borrow_out = (~a[1] & b[1]) | (~(a[1] ^ b[1]) & borrow_internal);
            
            borrow_subtractor = {borrow_out, result};
        end
    endfunction

    // 状态寄存器更新
    always @(posedge clk) begin
        curr_state <= next_state;
    end
    
    // 组合逻辑：下一状态逻辑
    always @(*) begin
        case(curr_state)
            IDLE: begin
                if (start)
                    next_state = COMPARE;
                else
                    next_state = IDLE;
            end
            
            COMPARE: begin
                next_state = DONE;
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // 数据处理逻辑
    always @(posedge clk) begin
        if (curr_state == IDLE && start) begin
            // 执行2位借位减法
            {borrow_chain, subtraction_result} <= borrow_subtractor(val_m[1:0], val_n[1:0]);
        end
    end
    
    // 判断相等性逻辑
    always @(posedge clk) begin
        if (curr_state == COMPARE) begin
            if (subtraction_result != 2'b00 || borrow_chain != 0) begin
                // 如果减法结果不为零或者有借位，说明不相等
                equal_result <= 0;
            end else if (WIDTH <= 2) begin
                // 如果宽度小于等于2位，只需要比较一次
                equal_result <= 1;
            end else begin
                // 比较剩余的位
                equal_result <= (val_m[WIDTH-1:2] == val_n[WIDTH-1:2]);
            end
        end
    end
    
    // 输出信号控制逻辑
    always @(posedge clk) begin
        case(curr_state)
            IDLE: begin
                done <= 0;
            end
            
            COMPARE: begin
                // 在COMPARE状态不修改输出
            end
            
            DONE: begin
                done <= 1;
                equal <= equal_result;
            end
            
            default: begin
                done <= 0;
                equal <= 0;
            end
        endcase
    end
endmodule