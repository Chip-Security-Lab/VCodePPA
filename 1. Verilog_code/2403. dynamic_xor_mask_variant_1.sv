//SystemVerilog
module dynamic_xor_mask #(
    parameter WIDTH = 64
)(
    input clk, en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] mask_reg;
    reg [WIDTH-1:0] next_mask;
    wire [WIDTH-1:0] complement_const;
    wire [WIDTH-1:0] subtracted_result;
    
    // 使用固定常量
    assign complement_const = 32'h9E3779B9;
    
    // 使用二进制补码减法算法实现
    assign subtracted_result = mask_reg + (~complement_const + 1'b1);
    
    always @(*) begin
        next_mask = en ? subtracted_result : mask_reg;
    end
    
    always @(posedge clk) begin
        mask_reg <= next_mask;
        if (en) begin
            data_out <= data_in ^ next_mask;
        end
    end
endmodule