//SystemVerilog
module circular_buffer #(
    parameter DW = 16,
    parameter DEPTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH) + 1
)(
    input clk,
    input rst,
    input push,
    input pop,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full,
    output empty
);
    // 缓冲区存储单元
    reg [DW-1:0] buffer [0:DEPTH-1];
    
    // 指针寄存器
    reg [PTR_WIDTH-1:0] wptr, rptr;
    reg [PTR_WIDTH-1:0] wptr_next, rptr_next;
    
    // 指针的低位部分用于寻址
    wire [PTR_WIDTH-2:0] waddr = wptr[PTR_WIDTH-2:0];
    wire [PTR_WIDTH-2:0] raddr = rptr[PTR_WIDTH-2:0];
    
    // 状态标志
    wire ptr_equal, msb_different;
    
    // 中间变量，分解条件逻辑
    wire push_valid, pop_valid;
    wire update_wptr, update_rptr;
    
    // 计算下一个指针值
    always @(*) begin
        wptr_next = wptr + 1'b1;
        rptr_next = rptr + 1'b1;
    end
    
    // 分解复杂条件表达式
    assign ptr_equal = (waddr == raddr);
    assign msb_different = (wptr[PTR_WIDTH-1] ^ rptr[PTR_WIDTH-1]);
    
    // 状态信号计算
    assign full = ptr_equal && msb_different;
    assign empty = ptr_equal && !msb_different;
    
    // 有效的操作条件
    assign push_valid = push && !full;
    assign pop_valid = pop && !empty;
    
    // 确定是否更新指针
    assign update_wptr = push_valid;
    assign update_rptr = pop_valid;
    
    // 写入逻辑
    always @(posedge clk) begin
        if (push_valid) begin
            buffer[waddr] <= din;
        end
    end
    
    // 指针更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            wptr <= 0;
            rptr <= 0;
        end else begin
            if (update_wptr) begin
                wptr <= wptr_next;
            end
            
            if (update_rptr) begin
                rptr <= rptr_next;
            end
        end
    end
    
    // 输出赋值
    assign dout = buffer[raddr];
    
endmodule