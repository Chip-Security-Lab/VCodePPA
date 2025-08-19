module idea_math_unit (
    input clk, mul_en,
    input [15:0] x, y,
    output reg [15:0] result
);
    wire [31:0] mul_temp = x * y;
    
    always @(posedge clk) begin
        if (mul_en) begin
            result <= (mul_temp == 32'h0) ? 16'hFFFF : 
                     (mul_temp % 17'h10001);
        end else begin
            result <= (x + y) % 65536;
        end
    end
endmodule
