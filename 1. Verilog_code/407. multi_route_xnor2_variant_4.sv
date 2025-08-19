//SystemVerilog
module multi_route_xnor2 (
    input  wire [7:0] input1, input2, input3,
    output reg  [7:0] output_xnor
);

    always @(*) begin
        // 原始: ~(input1 ^ input2) & ~(input2 ^ input3)
        // 使用布尔代数恒等式: XNOR(a,b) & XNOR(b,c) = ~(a^b) & ~(b^c) 
        // 可以简化为: (input1 == input2) && (input2 == input3)
        // 即: (input1 == input3)
        output_xnor = ~(input1 ^ input3);
    end

endmodule