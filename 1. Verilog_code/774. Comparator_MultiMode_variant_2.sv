//SystemVerilog
module Comparator_MultiMode #(
    parameter TYPE = 0, // 0:Equal,1:Greater,2:Less
    parameter WIDTH = 32
)(
    input               enable,   // 比较使能信号  
    input  [WIDTH-1:0]  a,b,
    output reg          res
);

    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] diff;
    wire equal, greater, less;
    
    // 借位减法器实现
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: sub_gen
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
            if(i < WIDTH-1) begin
                assign borrow[i+1] = (~a[i] & b[i]) | ((~a[i] | b[i]) & borrow[i]);
            end
        end
    endgenerate
    
    // 比较结果生成
    assign equal = ~(|diff);
    assign greater = ~borrow[WIDTH-1];
    assign less = borrow[WIDTH-1];
    
    // 使用if-else结构替代条件运算符
    always @(*) begin
        if (!enable) begin
            res = 1'b0;
        end else begin
            if (TYPE == 0) begin
                res = equal;
            end else if (TYPE == 1) begin
                res = greater;
            end else begin
                res = less;
            end
        end
    end
endmodule