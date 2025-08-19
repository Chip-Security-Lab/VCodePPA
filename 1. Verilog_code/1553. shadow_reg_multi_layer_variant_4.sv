//SystemVerilog
module shadow_reg_multi_layer #(parameter DW=8, DEPTH=3) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    // 内部信号声明
    reg [DW-1:0] shadow [0:DEPTH-1];
    reg [1:0] ptr;
    wire [1:0] next_ptr;
    
    // 条件反相减法器实现的指针更新逻辑
    wire [1:0] inverted_ptr;
    wire [1:0] sub_result;
    wire borrow;
    
    // 反相指针值（若ptr=DEPTH-1，则反相后为0）
    assign inverted_ptr = ~ptr;
    
    // 条件反相减法器实现
    // 当ptr=DEPTH-1时，计算(~ptr)+1，否则计算ptr+1
    assign {borrow, sub_result} = (ptr == DEPTH-1) ? 
                                  {1'b0, inverted_ptr + 2'b01} : 
                                  {1'b0, ptr + 2'b01};
    
    // 取结果
    assign next_ptr = (ptr == DEPTH-1) ? 2'b00 : sub_result;
    
    // 组合逻辑部分 - 输出读取
    assign data_out = shadow[ptr];
    
    // 时序逻辑部分 - 指针更新
    always @(posedge clk) begin
        if (rst)
            ptr <= 2'b00;
        else if (en)
            ptr <= next_ptr;
    end
    
    // 时序逻辑部分 - 数据存储
    always @(posedge clk) begin
        if (en)
            shadow[ptr] <= data_in;
    end
endmodule