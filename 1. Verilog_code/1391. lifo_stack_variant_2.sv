//SystemVerilog
module lifo_stack #(parameter DW=8, DEPTH=8) (
    input clk, rst_n,
    input push, pop,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full, empty
);
    // 存储元素的内存
    reg [DW-1:0] mem [0:DEPTH-1];
    // 指针寄存器
    reg [2:0] ptr;
    // 预计算下一个指针值
    wire [2:0] next_ptr;
    // 提前注册控制信号
    reg push_r, pop_r;
    reg [DW-1:0] din_r;
    
    // 提前缓存输入信号以减少输入到第一级寄存器的延迟
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            push_r <= 1'b0;
            pop_r <= 1'b0;
            din_r <= {DW{1'b0}};
        end else begin
            push_r <= push;
            pop_r <= pop;
            din_r <= din;
        end
    end
    
    // 使用显式多路复用器结构预计算下一个指针值
    wire [2:0] ptr_inc, ptr_dec, ptr_keep;
    wire sel_inc, sel_dec, sel_keep;
    
    assign ptr_inc = ptr + 1'b1;
    assign ptr_dec = ptr - 1'b1;
    assign ptr_keep = ptr;
    
    assign sel_inc = push_r && !pop_r && !full;
    assign sel_dec = !push_r && pop_r && !empty;
    assign sel_keep = !(sel_inc || sel_dec);
    
    assign next_ptr = (sel_inc) ? ptr_inc : 
                     (sel_dec) ? ptr_dec : 
                                ptr_keep;
    
    // 更新指针和内存
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr <= 3'b000;
        end else begin
            ptr <= next_ptr;
            if(push_r && !full) begin
                mem[ptr] <= din_r;
            end
        end
    end
    
    // 状态信号
    assign full = (ptr == DEPTH);
    assign empty = (ptr == 0);
    
    // 使用显式多路复用器输出数据
    wire [DW-1:0] mem_data;
    assign mem_data = mem[ptr-1];
    assign dout = mem_data;
    
endmodule