//SystemVerilog
module TriStateMatcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input [WIDTH-1:0] mask,  // 0=无关位
    output reg match
);

reg [WIDTH-1:0] masked_data;
reg [WIDTH-1:0] masked_pattern;
reg [WIDTH-1:0] diff;
reg [WIDTH-1:0] sum;
reg [WIDTH-1:0] carry;

always @(*) begin
    masked_data = data & mask;
    masked_pattern = pattern & mask;
    
    // 条件求和减法算法实现
    diff = masked_data ^ masked_pattern;
    carry = ~masked_data & masked_pattern;
    sum = diff;
    
    // 计算最终结果
    match = ~(|sum);
end

endmodule