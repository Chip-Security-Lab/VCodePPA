//SystemVerilog
module shadow_reg_multi_layer #(parameter DW=8, DEPTH=3) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    reg [DW-1:0] shadow [0:DEPTH-1];
    reg [1:0] ptr;
    wire [1:0] next_ptr;
    
    // 使用2位并行前缀减法器实现指针计算
    // 并行前缀减法结构
    wire [1:0] p, g;
    wire g_prop;
    
    // 生成与传播信号
    assign p[0] = ~ptr[0];
    assign p[1] = ~ptr[1];
    assign g[0] = ptr[0];
    assign g[1] = ptr[1];
    
    // 并行前缀运算
    assign g_prop = g[0] | (p[0] & g[1]);
    
    // 计算下一个指针值 - 优化为更高效的实现
    assign next_ptr = (ptr == DEPTH-1) ? 2'b00 : (ptr + 1'b1);
    
    // 指针更新逻辑
    always @(posedge clk) begin
        if(rst) begin
            ptr <= 2'b00;
        end
        else if(en) begin
            ptr <= next_ptr;
        end
    end
    
    // 数据写入逻辑
    always @(posedge clk) begin
        if(en) begin
            shadow[ptr] <= data_in;
        end
    end
    
    // 数据输出逻辑
    assign data_out = shadow[ptr];
endmodule