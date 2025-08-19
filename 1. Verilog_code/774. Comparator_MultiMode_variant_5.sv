//SystemVerilog
module Comparator_MultiMode #(
    parameter TYPE = 0, // 0:Equal,1:Greater,2:Less
    parameter WIDTH = 32
)(
    input               enable,   // 比较使能信号  
    input  [WIDTH-1:0]  a,b,
    output              res
);
    wire [WIDTH-1:0] diff;
    wire [WIDTH-1:0] prop, gen;
    wire [WIDTH:0] carry;
    wire borrow_out;
    
    // 计算初始传播和生成信号
    assign prop = a ^ b;
    assign gen = ~a & b;
    
    // 并行前缀计算进位传播
    assign carry[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: prefix_stage
            // 使用并行前缀算法计算每一位的借位
            if (i == 0) begin
                assign carry[i+1] = gen[i];
            end else begin
                assign carry[i+1] = gen[i] | (prop[i] & carry[i]);
            end
            // 计算差值
            assign diff[i] = prop[i] ^ carry[i];
        end
    endgenerate
    
    assign borrow_out = carry[WIDTH];
    
    wire equal   = (diff == {WIDTH{1'b0}});
    wire greater = ~borrow_out & ~equal;
    wire less    = borrow_out;
    
    assign res = enable ? 
                (TYPE == 0 ? equal : 
                 TYPE == 1 ? greater : less) 
                : 1'b0;
endmodule