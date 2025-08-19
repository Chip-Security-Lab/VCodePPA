//SystemVerilog
module Comparator_TriState #(parameter WIDTH = 12) (
    input              en,        // 输出使能
    input  [WIDTH-1:0] src1,
    input  [WIDTH-1:0] src2,
    output tri         equal
);
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] diff;
    wire cmp_result;
    
    // 借位减法器实现
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : SUB_GEN
            assign diff[i] = src1[i] ^ src2[i] ^ borrow[i];
            if (i < WIDTH-1) begin
                assign borrow[i+1] = (~src1[i] & src2[i]) | 
                                   ((~src1[i] | src2[i]) & borrow[i]);
            end
        end
    endgenerate
    
    // 比较结果：当差值为0且无借位时相等
    assign cmp_result = ~(|diff) & ~borrow[WIDTH-1];
    assign equal = en ? cmp_result : 1'bz;
endmodule