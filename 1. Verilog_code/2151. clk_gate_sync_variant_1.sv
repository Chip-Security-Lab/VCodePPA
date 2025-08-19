//SystemVerilog
module clk_gate_sync #(parameter WIDTH=8) (
    input clk, en,
    output [WIDTH-1:0] out
);
    reg [WIDTH-1:0] out_reg;
    reg [WIDTH-1:0] next_out;
    reg en_reg;
    
    wire [WIDTH-1:0] complement_one;
    wire [WIDTH-1:0] decrement_value;
    
    // 生成一补码
    assign complement_one = ~8'h01;
    // 生成二补码（用于实现减1操作）
    assign decrement_value = complement_one + 1'b1;
    
    always @(posedge clk) begin
        en_reg <= en;
        // 使用二进制补码实现减法（out_reg - 1 等效于 out_reg + (-1)）
        next_out <= out_reg + decrement_value;
        out_reg <= en_reg ? next_out : out_reg;
    end
    
    assign out = out_reg;
endmodule