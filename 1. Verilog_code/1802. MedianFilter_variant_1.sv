//SystemVerilog
module MedianFilter #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b, c,
    output reg [WIDTH-1:0] med
);
    reg [WIDTH-1:0] max_ab;
    reg [WIDTH-1:0] min_ab;
    
    always @(*) begin
        // 使用case语句计算a和b的最大值和最小值
        case ({a > b, a < b})
            2'b10: begin  // a > b
                max_ab = a;
                min_ab = b;
            end
            2'b01: begin  // a < b
                max_ab = b;
                min_ab = a;
            end
            default: begin  // a == b
                max_ab = a;
                min_ab = a;
            end
        endcase
        
        // 使用case语句确定中值
        case ({c > max_ab, c < min_ab})
            2'b10: med = max_ab;  // c > max_ab
            2'b01: med = min_ab;  // c < min_ab
            default: med = c;     // min_ab <= c <= max_ab
        endcase
    end
endmodule