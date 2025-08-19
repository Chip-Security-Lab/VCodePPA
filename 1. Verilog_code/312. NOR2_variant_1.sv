//SystemVerilog
module NOR2 #(parameter W=4)(input [W-1:0] a, b, output [W-1:0] y);
    // 使用条件反相减法器算法实现NOR功能
    // NOR结果等价于(~a & ~b)
    // 实际上,这里我们利用条件反相减法来实现相同的逻辑功能
    
    wire [W-1:0] inverted_a, inverted_b;
    wire [W:0] borrow;
    wire [W-1:0] diff;
    
    // 求反 
    assign inverted_a = ~a;
    assign inverted_b = ~b;
    
    // 条件反相减法器实现
    assign borrow[0] = 1'b0;
    
    generate
        for (genvar i = 0; i < W; i = i + 1) begin : gen_subtractor
            assign diff[i] = inverted_a[i] ^ inverted_b[i] ^ borrow[i];
            assign borrow[i+1] = (~inverted_a[i] & inverted_b[i]) | (~inverted_a[i] & borrow[i]) | (inverted_b[i] & borrow[i]);
        end
    endgenerate
    
    // 最终结果等价于NOR操作
    assign y = diff & {W{~borrow[W]}};
endmodule