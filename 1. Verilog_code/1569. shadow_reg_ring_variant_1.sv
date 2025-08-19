//SystemVerilog
module shadow_reg_ring #(parameter DW=8, DEPTH=4) (
    input clk, shift,
    input [DW-1:0] new_data,
    output [DW-1:0] oldest_data
);
    reg [DW-1:0] ring_reg [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    wire [$clog2(DEPTH)-1:0] next_wr_ptr;
    wire [$clog2(DEPTH)-1:0] read_ptr;
    
    // 使用显式多路复用器结构实现指针更新逻辑
    wire wr_ptr_at_max;
    assign wr_ptr_at_max = (wr_ptr == DEPTH-1);
    
    // 使用显式的MUX结构替代三元运算符
    wire [$clog2(DEPTH)-1:0] wr_ptr_plus_one;
    wire [$clog2(DEPTH)-1:0] zero_value;
    
    assign wr_ptr_plus_one = wr_ptr + 1'b1;
    assign zero_value = {$clog2(DEPTH){1'b0}};
    
    // 使用多路复用器模式明确条件选择
    assign next_wr_ptr = wr_ptr_at_max ? zero_value : wr_ptr_plus_one;
    
    // 读指针实现 - 同样使用多路复用器结构
    assign read_ptr = wr_ptr_at_max ? zero_value : wr_ptr_plus_one;
    
    // 初始化写指针
    initial wr_ptr = {$clog2(DEPTH){1'b0}};
    
    // 寄存器更新逻辑
    always @(posedge clk) begin
        if(shift) begin
            ring_reg[wr_ptr] <= new_data;
            wr_ptr <= next_wr_ptr;
        end
    end
    
    // 输出赋值
    assign oldest_data = ring_reg[read_ptr];
endmodule