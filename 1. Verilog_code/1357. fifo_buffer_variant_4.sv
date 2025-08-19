//SystemVerilog
module fifo_buffer #(
    parameter DEPTH = 8,
    parameter WIDTH = 16
)(
    input wire clk, rst,
    input wire [WIDTH-1:0] data_in,
    input wire push, pop,
    output reg [WIDTH-1:0] data_out,
    output wire empty, full
);
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] count;
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // 条件求和减法相关信号
    wire pop_valid;
    wire push_valid;
    wire [$clog2(DEPTH):0] count_plus_one;
    wire [$clog2(DEPTH):0] count_minus_one;
    wire [$clog2(DEPTH):0] count_next;
    
    // 读数据预取寄存器 - 将读取操作预先执行
    reg [WIDTH-1:0] pre_data_out;
    reg [$clog2(DEPTH)-1:0] next_rd_ptr;
    
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    
    // 定义有效操作条件
    assign pop_valid = pop && !empty;
    assign push_valid = push && !full;
    
    // 使用条件求和算法实现计数器更新
    assign count_plus_one = count + 1'b1;
    assign count_minus_one = {~count[0], ~count[$clog2(DEPTH):1]} + 1'b1; // 条件求和减法实现
    
    // 根据push和pop操作计算下一个count值
    assign count_next = (push_valid && !pop_valid) ? count_plus_one :
                        (!push_valid && pop_valid) ? count_minus_one :
                        count; // 如果同时push和pop，或者都不操作，count保持不变
    
    // 计算下一个读指针位置
    wire [$clog2(DEPTH)-1:0] rd_ptr_next = (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
    
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0; 
            rd_ptr <= 0; 
            count <= 0;
            data_out <= 0;
            pre_data_out <= 0;
            next_rd_ptr <= 0;
        end else begin
            count <= count_next;
            
            // 写操作逻辑
            if (push_valid) begin
                memory[wr_ptr] <= data_in;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end
            
            // 使用预取策略重新安排读操作
            if (pop_valid) begin
                data_out <= pre_data_out;  // 将预取的数据输出
                pre_data_out <= memory[rd_ptr_next];  // 预取下一个可能读取的数据
                rd_ptr <= rd_ptr_next;
                next_rd_ptr <= (rd_ptr_next == DEPTH-1) ? 0 : rd_ptr_next + 1;
            end else if (!empty) begin
                // 即使不弹出，也预先读取下一个数据，为未来的弹出操作做准备
                pre_data_out <= memory[rd_ptr];
                next_rd_ptr <= rd_ptr_next;
            end
        end
    end
endmodule