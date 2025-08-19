//SystemVerilog
module DeltaEncoder (
    input clk, rst_n,
    input [15:0] din,
    output reg [15:0] dout
);
    reg [15:0] prev;
    reg [15:0] din_reg;
    wire [15:0] prev_complement;
    wire [15:0] diff;
    wire carry;
    
    // 生成二进制补码 (~prev + 1)
    assign prev_complement = ~prev + 1'b1;
    
    // 使用补码加法实现减法 (din_reg + ~prev + 1)
    assign {carry, diff} = {1'b0, din_reg} + {1'b0, prev_complement};
    
    always @(posedge clk) begin
        if (!rst_n) begin
            prev <= 16'b0;
            din_reg <= 16'b0;
            dout <= 16'b0;
        end else begin
            din_reg <= din;
            prev <= din_reg;
            dout <= diff;
        end
    end
endmodule