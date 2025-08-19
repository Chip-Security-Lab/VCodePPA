//SystemVerilog
module shadow_reg_multi_layer #(parameter DW=8, DEPTH=3) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    // 存储数据的寄存器数组
    reg [DW-1:0] shadow [0:DEPTH-1];
    
    // 预解码指针和下一指针值，减少关键路径延迟
    reg [1:0] ptr;
    reg [1:0] next_ptr;
    
    // 提前计算指针是否到达边界
    wire ptr_at_boundary = (ptr == DEPTH-1);
    
    always @(*) begin
        // 预先计算下一个指针值，分离组合逻辑
        next_ptr = ptr_at_boundary ? 2'b00 : ptr + 1'b1;
    end
    
    always @(posedge clk) begin
        if(rst) begin
            ptr <= 2'b00;
        end
        else if(en) begin
            shadow[ptr] <= data_in;
            ptr <= next_ptr;
        end
    end
    
    // 输出逻辑保持不变
    assign data_out = shadow[ptr];
endmodule